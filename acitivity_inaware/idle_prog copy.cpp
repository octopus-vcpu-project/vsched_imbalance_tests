#include <iostream>
#include <pthread.h>
#include <stdio.h>
#include <unistd.h>
#include <chrono>
#include <thread>
#include <fstream>
#include <sstream>
#include <sys/time.h>
#include <sys/resource.h>
#include <vector>
#include <sys/types.h>
#include <sys/syscall.h>
#include <cstdlib>
#include <sys/vfs.h>
#include <cmath>
#include <deque>
#include <numeric>
using namespace std::chrono;
typedef uint64_t u64;


void moveThreadtoLowPrio(pid_t tid) {
    std::string path = "/sys/fs/cgroup/lw_prgroup/cgroup.threads";
    std::ofstream ofs(path, std::ios_base::app);
    if (!ofs) {
        std::cerr << "Could not open the file\n";
        return;
    }
    ofs << tid << "\n";
    ofs.close();
    struct sched_param params;
    params.sched_priority = sched_get_priority_min(SCHED_IDLE);
    sched_setscheduler(tid,SCHED_IDLE,&params);
}

void stressCore() {
    moveThreadtoLowPrio(syscall(SYS_gettid)); // Set the current thread to low priority
    int i = 0;
    while (true) {
	i+= 1;
	i-= 1;
    }
}

int main(int argc,char *argv[]) {
    unsigned int numCores = std::stoi(argv[1]); // Get number of available cores
    std::cout << "Launching stress tasks on " << numCores << " cores." << std::endl;

    std::vector<std::thread> threads;
    for (unsigned int i = 0; i < numCores; ++i) {
        threads.push_back(std::thread(stressCore));
    }
    for (auto &t : threads) {
        t.join();
    }

    return 0;
}
