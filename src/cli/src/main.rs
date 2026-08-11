mod cli_config;
mod position;
mod status;

use clap::{Parser, Subcommand};

#[derive(Parser)]
#[command(name = "qtcloud-human", version, about = "QtCloud Human CLI")]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// 招聘计划与进度
    Status(status::StatusArgs),
    /// 岗位管理
    Position(position::PositionArgs),
}

fn main() {
    let cli = Cli::parse();
    let result = match &cli.command {
        Commands::Status(args) => status::run(args),
        Commands::Position(args) => position::dispatch(args),
    };
    if let Err(e) = result {
        eprintln!("错误: {}", e);
        std::process::exit(1);
    }
}
