use async_trait::async_trait;
use std::collections::HashMap;
use std::path::{Path, PathBuf};

use crate::error::BindgenResult;
use crate::plugins::BuiltinPlugin;
use crate::{DojoContract, DojoData, DojoModel};

#[derive(Debug)]
pub struct BevyPlugin {}

impl BevyPlugin {
    pub fn new() -> Self {
        Self {}
    }
}

#[async_trait]
impl BuiltinPlugin for BevyPlugin {
    async fn generate_code(&self, data: &DojoData) -> BindgenResult<HashMap<PathBuf, Vec<u8>>> {
        let mut out: HashMap<PathBuf, Vec<u8>> = HashMap::new();

        for (name, model) in &data.models {
            let models_path = Path::new(&format!("components/{}.gen.rs", name)).to_owned();

            // pub models: HashMap<String, DojoModel>,

            println!("Generating Bevy components: {}", name);
            let code = String::from("use bevy::prelude::*;\n\n");

            out.insert(models_path, code.as_bytes().to_vec());
        }

        Ok(out)
    }
}
