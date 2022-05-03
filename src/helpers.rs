use {
    std::process,
    num_bigint::{BigUint},
    std::io::Read,
    std::io::Write,
    std::fs::File,
    std::str::FromStr,
};

use crate::math;

pub fn keygen(key_size : &u64) -> Result<(), std::io::Error> {
    if *key_size < 12 {
        println!("Unable to generate key: Key size must be at least 12 bits. Keys less than 12 bits have been proven unstable. Please try again.");
        process::exit(1);
    }
    println!("Generating key of size {}. This may take awhile...", key_size);
    let (mut n, mut e, mut d, mut phi) = math::keygen(key_size);
    while &d == &BigUint::from(1 as u32) || &e == &d || &e * &d % &phi != BigUint::from(1 as u32) {
        println!("Unable to find a valid e and d with generated values. Trying again with new p and q...");
        println!("Generating key of size {}. This may take awhile...", key_size);
        (n, e, d, phi) = math::keygen(key_size);
    }
    println!("Complete, your key is:");
    println!("");
    println!("Public Key (n e): {} {}", n, e);
    println!("Private Key (n d): {} {}", n, d);
    Ok(())
}

pub fn decrypt_file(n : BigUint, d : BigUint, input_filename : &str, output_filename: &str) -> Result<(), std::io::Error> {
    let mut file = File::open(input_filename)?;
    let mut contents = String::new();
    file.read_to_string(&mut contents)?;
    let mut file = File::create(output_filename)?;
    for c in contents.split_whitespace() {
        let m = math::decrypt(&n, &d, BigUint::from_str(c).expect("Failed to parse BigUint"));
        file.write_all(format!("{}", m as char).as_bytes())?;
    }
    println!("Decrypted file written to {}", output_filename);
    Ok(())
}

pub fn encrypt_file(n : BigUint, e : BigUint, input_filename : &str, output_filename: &str) -> Result<(), std::io::Error> {
    let mut file = File::create(output_filename).expect("Unable to create output file");
    let mut first_loop = true;
    std::fs::read(input_filename).unwrap().iter().for_each(|m| {
        if !first_loop {
            file.write_all(b"\n").unwrap();
        }
        let c = math::encrypt(&n, &e, *m);
        let c_str = c.to_str_radix(10);
        file.write_all(c_str.as_bytes()).expect("Unable to output file.");
        first_loop = false;
    });
    println!("Encrypted file written to {}", output_filename);
    Ok(())
}
