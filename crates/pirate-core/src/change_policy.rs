//! Change-address policy shared by transaction builders.

use pirate_params::Network;

/// Returns true when new Sapling change outputs should use ZIP-32 internal scope.
///
/// Sapling internal change is enabled at the same network height as Orchard/NU5.
/// Before that activation, Sapling-only transactions keep the legacy behavior of
/// returning change to the first selected Sapling spend address.
pub fn sapling_internal_change_active(network: &Network, target_height: u64) -> bool {
    match u32::try_from(target_height) {
        Ok(height) => network.is_orchard_active(height),
        Err(_) => network.orchard_activation_height.is_some(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn mainnet_keeps_legacy_sapling_change_until_activation_is_configured() {
        assert!(!sapling_internal_change_active(
            &Network::mainnet(),
            u64::from(u32::MAX)
        ));
    }

    #[test]
    fn testnet_activates_sapling_internal_change_at_orchard_height() {
        assert!(!sapling_internal_change_active(&Network::testnet(), 60));
        assert!(sapling_internal_change_active(&Network::testnet(), 61));
    }

    #[test]
    fn regtest_sapling_only_keeps_legacy_change_by_default() {
        // Regtest defaults to Sapling-only (Orchard/NU5 disabled), so Sapling
        // internal change stays in legacy mode regardless of height.
        assert!(!sapling_internal_change_active(&Network::regtest(), 1));
        assert!(!sapling_internal_change_active(&Network::regtest(), 1_000));
    }

    #[test]
    fn regtest_with_orchard_override_activates_internal_change() {
        // Users running an NU5-enabled regtest node can opt in via an Orchard
        // activation-height override, which re-enables Sapling internal change.
        let mut net = Network::regtest();
        net.orchard_activation_height = Some(1);
        assert!(sapling_internal_change_active(&net, 1));
    }
}
