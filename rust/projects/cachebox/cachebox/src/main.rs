use std::collections::HashMap;

struct Cache {
    data: HashMap<String, String>,
}

// TODO(human): Add an impl block for Cache with a fn new() -> Self
// Should return a Cache with an empty HashMap
// Hint: HashMap::new() creates empty map, Self { field: value } constructs the struct

fn main() {
    println!("cachebox v0.1.0");
}

#[cfg(test)]
mod tests {
    use super::*;
}
