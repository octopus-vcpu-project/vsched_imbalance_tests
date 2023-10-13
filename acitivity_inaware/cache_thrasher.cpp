#include <iostream>
#include <vector>
#include <random>
#include <chrono>
#include <cmath>

const size_t ARRAY_SIZE = 50000000; 
const size_t NUM_ITERATIONS = 100000000;  

double computePi(size_t iterations) {
    std::default_random_engine generator;
    std::uniform_real_distribution<double> distribution(0.0, 1.0);
    size_t insideCircle = 0;

    for (size_t i = 0; i < iterations; ++i) {
        double x = distribution(generator);
        double y = distribution(generator);
        if (x*x + y*y <= 1.0)
            insideCircle++;
    }

    return 4.0 * insideCircle / iterations;
}

int main() {
    std::vector<double> largeArray(ARRAY_SIZE);
    std::default_random_engine generator;
    std::uniform_int_distribution<size_t> distribution(0, ARRAY_SIZE - 1);
    
    for (size_t i = 0; i < ARRAY_SIZE; ++i) {
        largeArray[i] = i;
    }

    while (true) {
        for (size_t i = 0; i < ARRAY_SIZE; ++i) {
            size_t index = distribution(generator);
            largeArray[index] = computePi(10);
        }
    }
    return 0;
}