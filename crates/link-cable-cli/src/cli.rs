use std::fs;
use std::path::PathBuf;

use clap::{Parser, Subcommand, ValueEnum};
use link_cable_core::{Host, parse_manifest, plan, validate_policy};
use miette::{IntoDiagnostic, Result, miette};

#[derive(Debug, Parser)]
#[command(
    name = "link-cable",
    version,
    about = "Rust-first distribution substrate"
)]
struct Cli {
    #[command(subcommand)]
    command: Command,
}

#[derive(Debug, Subcommand)]
enum Command {
    /// Check that the local binary is usable.
    Doctor,
    /// Compute a dry-run distribution plan from a manifest.
    Plan {
        #[arg(long)]
        manifest: PathBuf,
        #[arg(long, default_value = "human")]
        format: OutputFormat,
    },
}

#[derive(Debug, Clone, Copy, ValueEnum)]
enum OutputFormat {
    Human,
    Json,
}

pub fn run() -> Result<()> {
    let cli = Cli::parse();
    match cli.command {
        Command::Doctor => {
            println!("link-cable doctor: ok (dry-run only, no publish credentials required)");
            Ok(())
        }
        Command::Plan { manifest, format } => {
            let input = fs::read_to_string(&manifest)
                .into_diagnostic()
                .map_err(|e| miette!("failed to read {}: {e}", manifest.display()))?;
            let manifest = parse_manifest(&input).map_err(|e| miette!(e.to_string()))?;
            // Run policy explicitly first so policy failures stop before any build/publish side effect.
            validate_policy(&manifest).map_err(|e| miette!(e.to_string()))?;
            let plan = plan(&manifest, Host::current()).map_err(|e| miette!(e.to_string()))?;
            match format {
                OutputFormat::Human => {
                    println!("{} {}", plan.package, plan.version);
                    println!("artifacts: {}", plan.artifacts.len());
                    println!("actions: {}", plan.actions.len());
                }
                OutputFormat::Json => {
                    println!("{}", serde_json::to_string_pretty(&plan).into_diagnostic()?);
                }
            }
            Ok(())
        }
    }
}
