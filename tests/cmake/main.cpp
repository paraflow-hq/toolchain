#include <iostream>
#include <vector>
#include <memory>
#include <string>
#include <algorithm>
#include <stdexcept>

// Test class with exception handling
class TestClass {
private:
    std::string name;
    std::vector<int> data;

public:
    TestClass(const std::string& n) : name(n) {
        data = {1, 2, 3, 4, 5};
    }

    void test_containers() {
        std::cout << "Testing containers with libc++..." << std::endl;
        
        // Test vector operations
        std::vector<int> vec = {10, 20, 30, 40, 50};
        std::cout << "Vector size: " << vec.size() << std::endl;
        
        // Test algorithms
        auto it = std::find(vec.begin(), vec.end(), 30);
        if (it != vec.end()) {
            std::cout << "Found value 30 at position: " << std::distance(vec.begin(), it) << std::endl;
        }
        
        // Test lambda with capture
        std::for_each(vec.begin(), vec.end(), [&](int& n) {
            n *= 2;
        });
        
        std::cout << "Vector after doubling: ";
        for (const auto& val : vec) {
            std::cout << val << " ";
        }
        std::cout << std::endl;
    }
    
    void test_smart_pointers() {
        std::cout << "Testing smart pointers with libc++..." << std::endl;
        
        // Test unique_ptr
        auto ptr = std::make_unique<std::string>("Hello from libc++");
        std::cout << "unique_ptr value: " << *ptr << std::endl;
        
        // Test shared_ptr
        auto shared1 = std::make_shared<int>(42);
        auto shared2 = shared1;
        std::cout << "shared_ptr value: " << *shared1 << ", use_count: " << shared1.use_count() << std::endl;
    }
    
    void test_exceptions() {
        std::cout << "Testing exception handling with libc++abi..." << std::endl;
        
        try {
            throw std::runtime_error("Test exception from libc++abi");
        } catch (const std::exception& e) {
            std::cout << "Caught exception: " << e.what() << std::endl;
        }
        
        try {
            std::vector<int> vec(5);
            vec.at(10) = 42; // This should throw std::out_of_range
        } catch (const std::out_of_range& e) {
            std::cout << "Caught out_of_range exception: " << e.what() << std::endl;
        }
    }
    
    const std::string& get_name() const { return name; }
};

int main() {
    std::cout << "=== Testing libc++ and libc++abi ===" << std::endl;
    
    try {
        TestClass test("LibcxxTest");
        std::cout << "Test object created: " << test.get_name() << std::endl;
        
        test.test_containers();
        std::cout << std::endl;
        
        test.test_smart_pointers();
        std::cout << std::endl;
        
        test.test_exceptions();
        std::cout << std::endl;
        
        std::cout << "All tests completed successfully!" << std::endl;
        return 0;
        
    } catch (const std::exception& e) {
        std::cerr << "Unexpected exception: " << e.what() << std::endl;
        return 1;
    }
}
