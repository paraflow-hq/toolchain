#include <iostream>
#include <vector>
#include <memory>
#include <string>
#include <algorithm>
#include <numeric>
#include <cmath>

// Test class for basic C++ features
class Calculator {
private:
    std::vector<double> history;

public:
    Calculator() = default;
    
    double add(double a, double b) {
        double result = a + b;
        history.push_back(result);
        return result;
    }
    
    double multiply(double a, double b) {
        double result = a * b;
        history.push_back(result);
        return result;
    }
    
    double power(double base, double exponent) {
        double result = std::pow(base, exponent);
        history.push_back(result);
        return result;
    }
    
    size_t getHistorySize() const {
        return history.size();
    }
    
    void printHistory() const {
        std::cout << "History: ";
        for (const auto& val : history) {
            std::cout << val << " ";
        }
        std::cout << std::endl;
    }
};

// Simple fibonacci function
int fibonacci(int n) {
    if (n <= 1) return n;
    return fibonacci(n - 1) + fibonacci(n - 2);
}

// String processing function
std::string processString(const std::string& input) {
    std::string result = input;
    std::transform(result.begin(), result.end(), result.begin(), ::toupper);
    return "Processed: " + result;
}

int main() {
    std::cout << "=== Emscripten C++ Test ===" << std::endl;
    
    // Test 1: Basic C++ features
    std::cout << "\n1. Testing basic C++ features..." << std::endl;
    std::vector<int> numbers = {1, 2, 3, 4, 5};
    std::cout << "Vector size: " << numbers.size() << std::endl;
    
    auto sum = std::accumulate(numbers.begin(), numbers.end(), 0);
    std::cout << "Sum of vector: " << sum << std::endl;
    
    // Test 2: Smart pointers and classes
    std::cout << "\n2. Testing smart pointers and classes..." << std::endl;
    auto calc = std::make_unique<Calculator>();
    
    double result1 = calc->add(10.5, 20.3);
    std::cout << "Addition: 10.5 + 20.3 = " << result1 << std::endl;
    
    double result2 = calc->multiply(7.0, 8.0);
    std::cout << "Multiplication: 7.0 * 8.0 = " << result2 << std::endl;
    
    double result3 = calc->power(2.0, 8.0);
    std::cout << "Power: 2.0^8.0 = " << result3 << std::endl;
    
    std::cout << "History size: " << calc->getHistorySize() << std::endl;
    calc->printHistory();
    
    // Test 3: Fibonacci
    std::cout << "\n3. Testing Fibonacci function..." << std::endl;
    for (int i = 0; i <= 10; i++) {
        std::cout << "Fibonacci(" << i << ") = " << fibonacci(i) << std::endl;
    }
    
    // Test 4: String processing
    std::cout << "\n4. Testing string processing..." << std::endl;
    std::string testString = "hello emscripten world";
    std::string processed = processString(testString);
    std::cout << "Original: \"" << testString << "\"" << std::endl;
    std::cout << "Processed: \"" << processed << "\"" << std::endl;
    
    // Test 5: STL algorithms
    std::cout << "\n5. Testing STL algorithms..." << std::endl;
    std::vector<int> data = {5, 2, 8, 1, 9, 3};
    std::cout << "Original data: ";
    for (int val : data) std::cout << val << " ";
    std::cout << std::endl;
    
    std::sort(data.begin(), data.end());
    std::cout << "Sorted data: ";
    for (int val : data) std::cout << val << " ";
    std::cout << std::endl;
    
    auto max_elem = *std::max_element(data.begin(), data.end());
    std::cout << "Max element: " << max_elem << std::endl;
    
    std::cout << "\n=== All tests completed successfully! ===" << std::endl;
    return 0;
}
