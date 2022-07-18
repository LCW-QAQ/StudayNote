#include <bits/stdc++.h>

template <typename T>
class BlockingQueue {
 private:
  std::queue<T> q_;

  std::mutex mutex_;

 public:
  BlockingQueue() {}
  BlockingQueue(BlockingQueue&) = delete;
  BlockingQueue& operator=(const BlockingQueue&) = delete;

  void push(T& t) {
    std::unique_lock<std::mutex> lock(mutex_);
    q_.push(t);
  }

  void push(T&& t) { push(t); }

  T& front() {
    std::unique_lock<std::mutex> lock(mutex_);
    return q_.front();
  }

  bool pop() {
    std::unique_lock<std::mutex> lock(mutex_);
    if (q_.empty()) {
      return false;
    }
    q_.pop();
    return true;
  }

  bool empty() {
    std::unique_lock<std::mutex> lock(mutex_);
    return q_.empty();
  }

  size_t size() {
    std::unique_lock<std::mutex> lock(mutex_);
    return q_.size();
  }
};

class ThreadPool {
 private:
  BlockingQueue<std::function<void()>> q_;

  std::vector<std::thread> woker_threads_;

  std::mutex cond_mutex;

  std::condition_variable cond_var;

  volatile bool shutdown_status_;

  class WokerThread {
   private:
    int32_t id_;

    ThreadPool* pool_;

   public:
    WokerThread(ThreadPool* pool, const int32_t id) : id_(id), pool_(pool) {}

    void operator()() {
      std::function<void()> func;

      bool dequeued = false;
      while (!pool_->shutdown_status_) {
        {
          std::unique_lock<std::mutex> lock(pool_->cond_mutex);
          // 队列为空, 休眠等待有任务时, 条件变量通知
          if (pool_->q_.empty()) {
            pool_->cond_var.wait(lock);
          }
          func = pool_->q_.front();
          std::cout << std::this_thread::get_id()
                    << " pop task, size: " << pool_->q_.size() << std::endl;
          dequeued = pool_->q_.pop();
        }
        if (dequeued) {
          // 拿到任务开始执行
          func();
        }
      }
    }
  };

 public:
  ThreadPool(const int n_threads)
      : woker_threads_(std::vector<std::thread>(n_threads)),
        shutdown_status_(false) {}

  ThreadPool(const ThreadPool&) = delete;
  ThreadPool(ThreadPool&&) = delete;
  ThreadPool& operator=(const ThreadPool&) = delete;
  ThreadPool& operator=(const ThreadPool&&) = delete;

  void start() {
    // 初始化线程
    for (int i = 0; i < woker_threads_.size(); i++) {
      woker_threads_.at(i) = std::thread(WokerThread(this, i));
    }
  }

  /**
   * @brief 线程池停机
   * 当前版本, 停机时只会将正在处理的任务完成
   * 任务队列中的剩余任务将会被忽略
   */
  void shutdown() {
    shutdown_status_ = true;
    cond_var.notify_all();

    // 等待所有线程执行完成
    for (auto&& t : woker_threads_) {
      if (t.joinable()) {
        t.join();
      }
    }
  }

  template <typename _Func, typename... _Args>
  void submit(_Func&& f, _Args&&... args) {
    std::function<decltype(f(args...))()> func =
        std::bind(std::forward<_Func>(f), std::forward<_Args>(args)...);

    std::function<void()> wrapper_func = [func]() { func(); };

    q_.push(wrapper_func);

    cond_var.notify_one();
  }

  ~ThreadPool() {
    if (!shutdown_status_) {
      shutdown();
    }
  }
};

int main() {
  ThreadPool pool{8};
  pool.start();
  for (int i = 0; i < 10; i++) {
    pool.submit([i]() {
      std::cout << "hello " << std::to_string(i)
                << ", thread_id: " << std::this_thread::get_id() << std::endl;
    });
  }
  return 0;
}