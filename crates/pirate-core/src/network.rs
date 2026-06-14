//! Pirate Chain network parameters for Zcash consensus integration.

use pirate_params::{Network, NetworkType};
use zcash_primitives::consensus::{BlockHeight, NetworkUpgrade, Parameters};

/// Pirate Chain network parameters
#[derive(Clone, Debug)]
pub struct PirateNetwork {
    pub(crate) network: Network,
}

impl PirateNetwork {
    /// Create parameters for the given network.
    pub fn new(network_type: NetworkType) -> Self {
        Self {
            network: Network::from_type(network_type),
        }
    }

    /// Create parameters from a custom network configuration.
    pub fn from_network(network: Network) -> Self {
        Self { network }
    }

    /// Mainnet parameters.
    pub fn mainnet() -> Self {
        Self::new(NetworkType::Mainnet)
    }

    /// Get the underlying network configuration.
    pub fn network(&self) -> &Network {
        &self.network
    }

    /// Get the network type.
    pub fn network_type(&self) -> NetworkType {
        self.network.network_type
    }
}

impl Default for PirateNetwork {
    fn default() -> Self {
        Self::mainnet()
    }
}

impl Parameters for PirateNetwork {
    fn coin_type(&self) -> u32 {
        self.network.coin_type
    }

    fn address_network(&self) -> Option<zcash_address::Network> {
        match self.network.network_type {
            NetworkType::Mainnet => Some(zcash_address::Network::Main),
            NetworkType::Testnet | NetworkType::Regtest => Some(zcash_address::Network::Test),
        }
    }

    fn hrp_sapling_extended_spending_key(&self) -> &str {
        match self.network.network_type {
            NetworkType::Mainnet => "secret-extended-key-main",
            NetworkType::Testnet => "secret-extended-key-test",
            NetworkType::Regtest => "secret-extended-key-regtest",
        }
    }

    fn hrp_sapling_extended_full_viewing_key(&self) -> &str {
        match self.network.network_type {
            NetworkType::Mainnet => "zxviews",
            NetworkType::Testnet => "zxviewtestsapling",
            NetworkType::Regtest => "zxviewregtestsapling",
        }
    }

    fn hrp_sapling_payment_address(&self) -> &str {
        match self.network.network_type {
            NetworkType::Mainnet => "zs",
            NetworkType::Testnet => "ztestsapling",
            NetworkType::Regtest => "zregtestsapling",
        }
    }

    fn b58_pubkey_address_prefix(&self) -> &[u8] {
        &[0x1C, 0xB8] // Pirate Chain P2PKH prefix
    }

    fn b58_script_address_prefix(&self) -> &[u8] {
        &[0x1C, 0xBD] // Pirate Chain P2SH prefix
    }

    fn activation_height(&self, nu: NetworkUpgrade) -> Option<BlockHeight> {
        match nu {
            NetworkUpgrade::Overwinter => Some(BlockHeight::from_u32(self.network.overwinter_activation_height)),
            NetworkUpgrade::Sapling => Some(BlockHeight::from_u32(self.network.sapling_activation_height)),
            NetworkUpgrade::Nu5 => self
                .network
                .orchard_activation_height
                .map(BlockHeight::from_u32),
            #[allow(unreachable_patterns)]
            _ => None,
        }
    }
}
