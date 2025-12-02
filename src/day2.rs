use std::{collections::HashSet, time::Instant};

use rayon::iter::{
    IntoParallelIterator, IntoParallelRefIterator, ParallelBridge, ParallelIterator,
};

const INPUT: &str = "8284583-8497825,7171599589-7171806875,726-1031,109709-251143,1039-2064,650391-673817,674522-857785,53851-79525,8874170-8908147,4197684-4326484,22095-51217,92761-107689,23127451-23279882,4145708930-4145757240,375283-509798,585093-612147,7921-11457,899998-1044449,3-19,35-64,244-657,5514-7852,9292905274-9292965269,287261640-287314275,70-129,86249864-86269107,5441357-5687039,2493-5147,93835572-94041507,277109-336732,74668271-74836119,616692-643777,521461-548256,3131219357-3131417388";

pub fn run() {
    let now = Instant::now();
    part1();
    let elapsed = now.elapsed();
    println!("Part1 Elapsed: {}ms", elapsed.as_millis());

    let now = Instant::now();
    part2();
    let elapsed = now.elapsed();
    println!("Part2 Elapsed: {}ms", elapsed.as_millis());
}

fn is_invalid(str: &str) -> bool {
    if str.len() % 2 != 0 {
        return false;
    }

    let (l, r) = str.split_at(str.len() / 2);
    l == r
}

fn part1() {
    let input: Vec<&str> = INPUT.split(',').collect();
    let mapped = input
        .into_iter()
        .map(|s| s.split_at(s.find('-').unwrap()))
        .map(|(l, r)| (l, &r[1..]))
        .map(|(l, r)| (l.parse::<usize>().unwrap())..(r.parse::<usize>().unwrap()))
        .collect::<Vec<_>>();

    let mut count = 0;
    for range in mapped {
        for id in range {
            if is_invalid(&format!("{}", id)) {
                count += id;
            }
        }
    }

    println!("P1: {}", count);
}

fn is_invalid2(id: usize) -> bool {
    let digits = id.ilog10() + 1;

    'outer: for d in (1..=digits / 2).rev().filter(|d| digits % d == 0) {
        let m = 10u64.pow(d);
        let pat = id as u64 % m;
        for i in 1..(digits / d) {
            if pat != (id as u64 / 10u64.pow(d * i)) % m {
                continue 'outer;
            }
        }

        return true;
    }

    false
}

fn part2() {
    let input = INPUT.split(',');
    let sum: usize = input
        .par_bridge()
        .map(|s| s.split_at(s.find('-').unwrap()))
        .map(|(l, r)| (l, &r[1..]))
        .flat_map(|(l, r)| (l.parse::<usize>().unwrap())..(r.parse::<usize>().unwrap()))
        .filter(|id| is_invalid2(*id))
        .sum();
    println!("P2: {}", sum);
}
