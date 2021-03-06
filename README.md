[![Build Status](https://drone.jeffresc.dev/api/badges/JeffResc/rust_rsa/status.svg)](https://drone.jeffresc.dev/JeffResc/rust_rsa)

# rust_rsa
An implementation of RSA key generation, file encryption and file decryption in Rust.

**Do not use this library for anything other than testing purposes.**

## Features
* Generate RSA keys of specified size
* Encrypt files
* Decrypt files

## Known limitations
* Can only encrypt files with ASCII characters. If non-ASCII characters are in file, they will become corrupted, but ASCII characters in the file will be preserved.
* There are some limitations on the maximum values of different variables. Most variables roughly have a maximum value of `3.079 x 10^22212093154093428519` with the exception of e and phi. All variables are represented as [BigUint](https://docs.rs/num-bigint/latest/num_bigint/struct.BigUint.html) with the exception of e and phi which are represented as [BigInt](https://docs.rs/num-bigint/latest/num_bigint/struct.BigInt.html). For more information on the maximum values, see [*Is there a limit to the size of a BigInt or BigUint in Rust?*](https://stackoverflow.com/questions/50504503/is-there-a-limit-to-the-size-of-a-bigint-or-biguint-in-rust/)

## Dependencies
* [clap](https://crates.io/crates/clap)
* [rand](https://crates.io/crates/rand)
* [num-bigint](https://crates.io/crates/num-bigint)
* [num-integer](https://crates.io/crates/num-integer)
* [num-traits](https://crates.io/crates/num-traits)

## Installation
Use a pre-compiled binary in releases or build from source:
```bash
cargo install --git https://github.com/JeffResc/rust_rsa
```

### Main
``` 
An implementation of RSA encryption in Rust by Jeffrey Rescignano for CS 456.

USAGE:
    rust_rsa <SUBCOMMAND>

OPTIONS:
    -h, --help    Print help information

SUBCOMMANDS:
    decrypt    Decrypts a file
    encrypt    Encrypts a file
    help       Print this message or the help of the given subcommand(s)
    keygen     Generate a public/private key pair
```

### Decrypt
```
Decrypts a file

USAGE:
    rust_rsa decrypt <PRIVATE_KEY_N> <PRIVATE_KEY_D> <INPUT_FILE> <OUTPUT_FILE>

ARGS:
    <PRIVATE_KEY_N>    Private key n
    <PRIVATE_KEY_D>    Private key d
    <INPUT_FILE>       File to decrypt
    <OUTPUT_FILE>      Decrypted file

OPTIONS:
    -h, --help    Print help information
```

### Encrypt
```
Encrypts a file

USAGE:
    rust_rsa encrypt <PUBLIC_KEY_N> <PUBLIC_KEY_E> <INPUT_FILE> <OUTPUT_FILE>

ARGS:
    <PUBLIC_KEY_N>    Public key n
    <PUBLIC_KEY_E>    Public key e
    <INPUT_FILE>      File to encrypt
    <OUTPUT_FILE>     Encrypted file

OPTIONS:
    -h, --help    Print help information
```

### Keygen
```
Generate a public/private key pair

USAGE:
    rust_rsa keygen <KEY_SIZE>

ARGS:
    <KEY_SIZE>    Key size in bits

OPTIONS:
    -h, --help    Print help information
```
