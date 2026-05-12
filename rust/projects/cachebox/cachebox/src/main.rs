use std::collections::HashMap;

struct Cache {
    data: HashMap<String, String>,
}

impl Cache {
    fn new() -> Self {
        Self {
            data: HashMap::new()
        }
    }
    
    fn set(&mut self, key: &str, value: &str) {
        self.data.insert(key.to_string(), value.to_string());
    }

    // TODO(human): Implement get(&self, key: &str) -> Option<&String>
    // Return a reference to the value if key exists, None otherwise
    // Hint: HashMap::get(key) already returns Option<&V>
}

fn main() {
    println!("cachebox v0.1.0");
}

#[cfg(test)]
mod tests {
    use super::*;
}
