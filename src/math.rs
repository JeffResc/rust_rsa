use {
    num_bigint::{BigUint, RandBigInt, ToBigInt},
    std::process,
    num_traits::{One, Zero},
    num_integer::{Integer, ExtendedGcd},
};

#[inline(always)]
pub fn decrypt(n : &BigUint, d : &BigUint, c : BigUint) -> u8 {
    // b = c ^ d mod n
    return u8::from_str_radix(&c.modpow(d, n).to_str_radix(10), 10).unwrap();
}

#[inline(always)]
pub fn encrypt(n : &BigUint, e : &BigUint, b : u8) -> BigUint {
    if BigUint::from(b) >= *n {
        println!("Unable to encrypt. b is larger than or equal to n.");
        process::exit(1);
    }
    // c = b ^ e mod n
    return BigUint::from(b).modpow(e, n);
}

fn ed_keygen(phi : &BigUint) -> (BigUint, BigUint) {
    let mut rng = rand::thread_rng();
    print!("Generating e... ");
    let e = rng.gen_biguint_range(&BigUint::from(3u64), &phi);
    println!("done!");
    print!("Calculating d... ");
    let d = modinv(&e, &phi);
    println!("done!");
    return (e, d);
}

pub fn keygen(key_size : &u64) -> (BigUint, BigUint, BigUint, BigUint) {
    let mut rng = rand::thread_rng();
    print!("Generating p... ");
    let mut p = rng.gen_biguint(*key_size);
    // ensure p is prime
    while !is_prime(&p, &40) {
        p = rng.gen_biguint(*key_size);
    }
    println!("done!");
    print!("Generating q... ");
    let mut q = rng.gen_biguint(*key_size);
    // ensure q != p and q is prime
    while p != q && !is_prime(&q, &40) {
        q = rng.gen_biguint(*key_size);
    }
    println!("done!");
    print!("Calculating n... ");
    let n = &p * &q;
    println!("done!");
    print!("Calculating phi... ");
    let phi = (&p - BigUint::from(1 as u32)) * (&q - BigUint::from(1 as u32));
    println!("done!");
    let mut attempts = 1;
    let (mut e, mut d) = ed_keygen(&phi);
    while &d == &BigUint::from(1 as u32) || &e == &d || &e * &d % &phi != One::one() {
        println!("Unable to find the inverse of e. Trying again with same p and q... (Attempt {} of 10)", attempts);
        (e, d) = ed_keygen(&phi);
        if attempts >= 10 {
            return (BigUint::from(0 as u32), BigUint::from(0 as u32), BigUint::from(0 as u32), BigUint::from(0 as u32));
        }
        attempts += 1;
    }
    return (n, e, d, phi);
}

fn modinv(a: &BigUint, m: &BigUint) -> BigUint {
    let ExtendedGcd { gcd, x, y: _ } = a.to_bigint().unwrap().extended_gcd(&m.to_bigint().unwrap());
    if gcd != One::one() || x < Zero::zero() {
        return BigUint::from(0 as u32);
    } else {
        return x.to_biguint().unwrap() % m;
    }
}

fn rabin_miller(n : &BigUint, k : &u8) -> bool {
    let (mut s, mut t) = (n - BigUint::from(1 as u32), 0);
    while &s % BigUint::from(2 as u32) == Zero::zero() {
        s /= BigUint::from(2 as u32);
        t += 1;
    }
    for _ in 0..*k {
        let a = rand::thread_rng().gen_biguint_range(&BigUint::from(2 as u32), &(n - BigUint::from(1 as u32)));
        let mut v = a.modpow(&s, &n);
        if v != One::one() {
            let mut i = 0;
            while v != (n - BigUint::from(1 as u32)) {
                if i == t - 1 {
                    return false;
                } else {
                    i += 1;
                    v = v.modpow(&BigUint::from(2 as u32), &n);
                }
            }
        }
    }
    return true;
}

fn is_prime(n : &BigUint, k : &u8) -> bool {
    //println!("Testing: {}", n);
    if *n <= One::one() {
        return false;
    } else if *n == BigUint::from(2 as u32) {
        return true;
    } else if n.clone() % BigUint::from(2 as u32) == Zero::zero() {
        return false;
    }

    return rabin_miller(&n, k);
}
