//! YUNG's Better Mineshafts for Horizon — the one `impl Hooks` at the crate root.
//!
//! | Moment | What the port does |
//! |---|---|
//! | [`Mod::register`] | `register_structure_type("mineshaft", …)`: the type the jar's thirteen data-pack structures name (`"type": "bettermineshafts:mineshaft"`) now has a generator, so they stop being `Unsupported` |
//! | [`Mod::register_commands`] | declares `/bettermineshafts status` |
//! | [`Mod::run_mod_command`] | answers it from [`runtime::status_lines`] |
//!
//! The mod's own geometry is [`pieces`] (the four piece kinds, saved and loaded like any structure
//! piece) over [`runtime`] (the pure layout: chain rules, boxes, clamps, the budget, the palette,
//! the readout), with [`support`] as the thin glue between them and the SDK.
//!
//! LOCAL-ONLY until publication is approved (ARCHITECTURE.md §8): LGPL-3.0-only, rank 1,
//! publishable under the same licence with this complete source.

pub mod pieces;
pub mod runtime;
pub mod support;

use mod_api::{
    self, Flow, Hooks, RegisterCommandsEvent, Registrar, RegistrationContext, RunModCommandEvent,
    ServerHost,
};

#[derive(Default)]
struct Mod;

#[mod_api::horizon_mod]
impl Hooks for Mod {
    /// Once, at startup: the structure type the carried data-pack definitions name.
    fn register(&self, r: &mut dyn Registrar, _cx: &RegistrationContext) {
        support::register(r);
    }

    /// Declare `/bettermineshafts status` in the server's command tree.
    fn register_commands(&self, _host: &mut dyn ServerHost, event: &mut RegisterCommandsEvent<'_>) {
        support::declare_commands(event.commands);
    }

    /// Answer `/bettermineshafts status` and take the command.
    fn run_mod_command(
        &self,
        host: &mut dyn ServerHost,
        event: &mut RunModCommandEvent<'_>,
    ) -> Flow {
        support::run_command(host, event)
    }
}
