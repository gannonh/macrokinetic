//
//  SeededRNG.swift
//  JabTracker
//
//  Seeded random number generator for reproducible mock data generation.
//  Uses GameplayKit's Mersenne Twister algorithm.
//

import GameplayKit

/// Random number generator with seed for reproducible mock data
struct SeededRNG: RandomNumberGenerator {
    private var source: GKMersenneTwisterRandomSource

    init(seed: UInt64) {
        source = GKMersenneTwisterRandomSource(seed: seed)
    }

    mutating func next() -> UInt64 {
        let high = UInt64(bitPattern: Int64(source.nextInt()))
        let low = UInt64(bitPattern: Int64(source.nextInt()))
        return (high << 32) | (low & 0xFFFF_FFFF)
    }
}
