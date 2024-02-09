#include <iostream>
#include <cstdlib>
#include <ctime>
#include <new> // For std::nothrow

int main() {
    // Size of the memory buffer to allocate (100 MB for example).
    const size_t BUFFER_SIZE = 100 * 1024 * 1024; // Adjust as needed
    const size_t CACHE_LINE_SIZE = 64; // Size of cache line

    // Allocate the buffer.
    char *buffer = new (std::nothrow) char[BUFFER_SIZE];
    if (!buffer) {
        std::cerr << "Memory allocation failed." << std::endl;
        return 1;
    }

    // Seed the random number generator.
    std::srand(static_cast<unsigned>(std::time(nullptr)));

    // Endless loop to continuously access random cache lines.
    while (true) {
        // Generate a random index aligned to cache line size.
        size_t random_index = (std::rand() % (BUFFER_SIZE / CACHE_LINE_SIZE)) * CACHE_LINE_SIZE;

        // Access a random cache line in the buffer to "pollute" the cache.
        // The volatile keyword is used to prevent compiler optimizations that may skip the access.
        volatile char data = buffer[random_index];

        // Optionally perform a write operation.
        buffer[random_index] = data;

        // You could add a small delay here if you want to control the rate of access.
    }

    // Normally we would free the buffer, but this code will never reach here due to the infinite loop.
    // delete[] buffer;

    return 0;
}