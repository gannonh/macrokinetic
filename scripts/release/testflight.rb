#!/usr/bin/env ruby

# Minimal App Store Connect client for release ownership and group assertions.
# Uploading remains Fastlane/Transporter work; this file owns API reads/writes.

require "base64"
require "json"
require "net/http"
require "openssl"
require "securerandom"
require "time"
require "uri"

APP_ID = ENV.fetch("ASC_APP_ID", "6757370520")
TEAM_ID = ENV.fetch("APPLE_TEAM_ID", "ZBZKKWF95G")
API_BASE = "https://api.appstoreconnect.apple.com/v1"

def api_request(method, path, body = nil)
  uri = URI("#{API_BASE}#{path}")
  request = Net::HTTP.const_get(method.capitalize).new(uri)
  request["Authorization"] = "Bearer #{jwt}"
  request["Content-Type"] = "application/json"
  request.body = JSON.generate(body) if body
  response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(request) }
  unless response.is_a?(Net::HTTPSuccess)
    warn "App Store Connect #{method.upcase} #{path} failed: #{response.code} #{response.body}"
    exit 1
  end
  response.body.empty? ? {} : JSON.parse(response.body)
end

def jwt
  key_id = ENV.fetch("ASC_KEY_ID")
  issuer_id = ENV.fetch("ASC_ISSUER_ID")
  private_key = Base64.decode64(ENV.fetch("ASC_PRIVATE_KEY_BASE64"))
  header = encode({ alg: "ES256", kid: key_id, typ: "JWT" })
  payload = encode({ iss: issuer_id, iat: Time.now.to_i, exp: Time.now.to_i + 1_000, aud: "appstoreconnect-v1" })
  signing_input = "#{header}.#{payload}"
  der_signature = OpenSSL::PKey::EC.new(private_key).sign(OpenSSL::Digest::SHA256.new, signing_input)
  r, s = OpenSSL::ASN1.decode(der_signature).value.map { |value| value.value.to_i }
  signature = [r.to_s(16).rjust(64, "0"), s.to_s(16).rjust(64, "0")].map { |value| [value].pack("H*") }.join
  "#{signing_input}.#{Base64.urlsafe_encode64(signature, padding: false)}"
end

def encode(value)
  Base64.urlsafe_encode64(JSON.generate(value), padding: false)
end

def builds_for_version(version)
  query = URI.encode_www_form_component(version)
  pre_release_versions = api_request(
    "get",
    "/preReleaseVersions?filter[app]=#{APP_ID}&filter[version]=#{query}&filter[platform]=IOS&limit=200",
  )["data"] || []

  pre_release_versions.flat_map do |pre_release_version|
    api_request(
      "get",
      "/preReleaseVersions/#{pre_release_version.fetch("id")}/builds?limit=200",
    )["data"] || []
  end
end

def builds(version, build)
  builds_for_version(version).select do |item|
    item.dig("attributes", "version").to_s == build.to_s
  end
end

def write_immutable(path, payload)
  abort "receipt already exists: #{path}" if File.exist?(path)
  File.write(path, JSON.pretty_generate(payload) + "\n", mode: "wx")
end

def sha256(path)
  digest = OpenSSL::Digest::SHA256.new
  File.open(path, "rb") { |file| while (chunk = file.read(1_048_576)); digest.update(chunk); end }
  digest.hexdigest
end

command = ARGV.shift
case command
when "next-build"
  version = ARGV.fetch(0)
  numbers = builds_for_version(version).filter_map do |item|
    Integer(item.dig("attributes", "version"), exception: false)
  end
  puts(numbers.empty? ? 1 : numbers.max + 1)
when "assert-unique"
  version, build = ARGV
  abort "version and build are required" unless version && build
  abort "App Store Connect already contains #{version} (#{build})" unless builds(version, build).empty?
when "existing-build"
  version, build = ARGV
  found = builds(version, build)
  puts(found.first && found.first["id"])
when "write-delivery-receipt"
  ipa, output, delivery_id, version, build, run_id, commit_sha = ARGV
  abort "delivery identifier is required" if delivery_id.to_s.empty?
  write_immutable(output, {
    "stage" => "delivery",
    "delivery_identifier" => delivery_id,
    "app_id" => APP_ID,
    "team_id" => TEAM_ID,
    "marketing_version" => version,
    "build_number" => build,
    "github_run_id" => run_id,
    "github_sha" => commit_sha,
    "ipa_sha256" => sha256(ipa),
    "created_at" => Time.now.utc.iso8601,
  })
when "poll-and-bind"
  version, build, delivery_receipt, output, run_id, commit_sha = ARGV
  delivery = JSON.parse(File.read(delivery_receipt))
  abort "delivery receipt provenance mismatch" unless delivery["github_run_id"] == run_id && delivery["github_sha"] == commit_sha
  deadline = Time.now + 60 * 60
  found = []
  loop do
    found = builds(version, build)
    break unless found.empty? || Time.now >= deadline
    sleep 30
  end
  abort "App Store Connect processing timed out for #{version} (#{build})" if found.empty?
  build_id = found.first["id"]
  write_immutable(output, {
    "stage" => "binding",
    "delivery_identifier" => delivery["delivery_identifier"],
    "build_resource_id" => build_id,
    "app_id" => APP_ID,
    "marketing_version" => version,
    "build_number" => build,
    "github_run_id" => run_id,
    "github_sha" => commit_sha,
    "ipa_sha256" => delivery["ipa_sha256"],
    "created_at" => Time.now.utc.iso8601,
  })
when "assert-groups"
  selected = ARGV.fetch(0)
  groups = api_request("get", "/apps/#{APP_ID}/betaGroups?limit=200")["data"] || []
  targets = {}
  ["dev", "internal"].each do |name|
    matches = groups.select { |group| group.dig("attributes", "name") == name }
    abort "#{name} must resolve to exactly one group" unless matches.one?
    attributes = matches.first["attributes"]
    abort "#{name} is not an internal explicit-access group" unless attributes["isInternalGroup"] == true && attributes["hasAccessToAllBuilds"] == false
    targets[name] = matches.first["id"]
  end
  puts JSON.generate("selected" => selected, "selected_id" => targets.fetch(selected), "nonselected_id" => targets.fetch(selected == "dev" ? "internal" : "dev"))
when "assign-exclusive"
  binding_path, selected, run_id, commit_sha = ARGV
  binding = JSON.parse(File.read(binding_path))
  abort "binding receipt provenance mismatch" unless binding["github_run_id"] == run_id && binding["github_sha"] == commit_sha
  group_info = JSON.parse(`#{File.expand_path(__FILE__)} assert-groups #{selected}`)
  build_id = binding.fetch("build_resource_id")
  memberships = {}
  { "selected" => group_info.fetch("selected_id"), "nonselected" => group_info.fetch("nonselected_id") }.each do |key, group_id|
    relationship = api_request("get", "/betaGroups/#{group_id}/relationships/builds?limit=200")["data"] || []
    memberships[key] = relationship.any? { |item| item["id"] == build_id }
  end
  abort "build is already associated with the non-selected group" if memberships["nonselected"]
  unless memberships["selected"]
    api_request("post", "/betaGroups/#{group_info.fetch("selected_id")}/relationships/builds", { data: [{ type: "builds", id: build_id }] })
  end
  memberships["selected"] = true
  final_nonselected = (api_request("get", "/betaGroups/#{group_info.fetch("nonselected_id")}/relationships/builds?limit=200")["data"] || []).any? { |item| item["id"] == build_id }
  final_selected = (api_request("get", "/betaGroups/#{group_info.fetch("selected_id")}/relationships/builds?limit=200")["data"] || []).any? { |item| item["id"] == build_id }
  abort "exclusive TestFlight assignment assertion failed" unless final_selected && !final_nonselected
  puts JSON.generate("selected_group" => selected, "build_resource_id" => build_id)
else
  abort "unknown command: #{command}"
end
