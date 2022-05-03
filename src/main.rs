use {
    clap::{arg, Command},
    num_bigint::BigUint,
    std::str::FromStr,
};

mod helpers;
mod math;

fn cli() -> Command<'static> {
    Command::new("rust_rsa")
        .about("An implementation of RSA encryption in Rust by Jeffrey Rescignano for CS 456.")
        .subcommand_required(true)
        .arg_required_else_help(true)
        .allow_external_subcommands(true)
        .allow_invalid_utf8_for_external_subcommands(true)
        .subcommand(
            Command::new("keygen")
                .about("Generate a public/private key pair")
                .arg(arg!(<KEY_SIZE> "Key size in bits"))
                .arg_required_else_help(true),
        )
        .subcommand(
            Command::new("encrypt")
                .about("Encrypts a file")
                .arg(arg!(<PUBLIC_KEY_N> "Public key n"))
                .arg(arg!(<PUBLIC_KEY_E> "Public key e"))
                .arg(arg!(<INPUT_FILE> "File to encrypt"))
                .arg(arg!(<OUTPUT_FILE> "Encrypted file"))
                .arg_required_else_help(true),
        )
        .subcommand(
            Command::new("decrypt")
                .about("Decrypts a file")
                .arg(arg!(<PRIVATE_KEY_N> "Private key n"))
                .arg(arg!(<PRIVATE_KEY_D> "Private key d"))
                .arg(arg!(<INPUT_FILE> "File to decrypt"))
                .arg(arg!(<OUTPUT_FILE> "Decrypted file"))
                .arg_required_else_help(true)
        )
}

fn main() {
    let matches = cli().get_matches();

    match matches.subcommand() {
        Some(("keygen", sub_matches)) => {
            let _ = helpers::keygen(
                &u64::from_str(
                    sub_matches.value_of("KEY_SIZE").expect("required")
                ).expect("Failed to parse key size")
            );
        }
        Some(("encrypt", sub_matches)) => {
            let _ = helpers::encrypt_file(
                sub_matches.value_of("PUBLIC_KEY_N").expect("required").parse::<BigUint>().expect("Invalid public key N"),
                sub_matches.value_of("PUBLIC_KEY_E").expect("required").parse::<BigUint>().expect("Invalid public key E"),
                sub_matches.value_of("INPUT_FILE").expect("required"),
                sub_matches.value_of("OUTPUT_FILE").expect("required")
            );
        }
        Some(("decrypt", sub_matches)) => {
            let _ = helpers::decrypt_file(
                sub_matches.value_of("PRIVATE_KEY_N").expect("required").parse::<BigUint>().expect("Invalid private key N"),
                sub_matches.value_of("PRIVATE_KEY_D").expect("required").parse::<BigUint>().expect("Invalid private key D"),
                sub_matches.value_of("INPUT_FILE").expect("required"),
                sub_matches.value_of("OUTPUT_FILE").expect("required")
            );
        }
        Some((ext, sub_matches)) => {
            let args = sub_matches
                .values_of_os("")
                .unwrap_or_default()
                .collect::<Vec<_>>();
            println!("Calling out to {:?} with {:?}", ext, args);
        }
        _ => unreachable!(),
    }
}
