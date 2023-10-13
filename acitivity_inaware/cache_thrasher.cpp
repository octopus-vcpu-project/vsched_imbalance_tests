#include <iostream>
#include <vector>
#include <random>
#include <chrono>
#include <cmath>
#include <thread>

const size_t ARRAY_SIZE = 50000000; 
const size_t NUM_ITERATIONS = 1000000000; 

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

void stressCore() {
    std::vector<double> largeArray(ARRAY_SIZE);
    std::default_random_engine generator;
    std::uniform_int_distribution<size_t> distribution(0, ARRAY_SIZE - 1);

    for (size_t i = 0; i < ARRAY_SIZE; ++i) {
        largeArray[i] = i;
    }

    while (true) {
        for (size_t i = 0; i < ARRAY_SIZE; ++i) {
            size_t index = distribution(generator);
            size_t index2 = distribution(generator);
            largeArray[index] = largeArray[index2] + computePi(3);
        }
    }
}

int main() {
    unsigned int numCores = std::thread::hardware_concurrency();
    std::cout << "Launching stress tasks on " << numCores << " cores." << std::endl;

    std::vector<std::thread> threads;

    for(unsigned int i = 0; i < numCores; ++i) {
        threads.push_back(std::thread(stressCore));
    }

    for(auto &t : threads) {
        t.join();
    }

    return 0;
}