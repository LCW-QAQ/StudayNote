# Quartz

## 配置

```java
@Configuration
public class QuartzConfig {

    /*
    解决QuartzJob中注入SpringBean为null的问题
     */
    @Component
    @RequiredArgsConstructor
    public static class QuartzJobFactory extends AdaptableJobFactory {
        private final AutowireCapableBeanFactory autowireCapableBeanFactory;

        @Override
        protected Object createJobInstance(TriggerFiredBundle bundle) throws Exception {
            final Object jobInstance = super.createJobInstance(bundle);
            autowireCapableBeanFactory.autowireBean(jobInstance);
            return jobInstance;
        }
    }

    @Bean
    public Scheduler scheduler(QuartzJobFactory quartzJobFactory) throws Exception {
        final SchedulerFactoryBean schedulerFactoryBean = new SchedulerFactoryBean();
        schedulerFactoryBean.setJobFactory(quartzJobFactory);
        schedulerFactoryBean.afterPropertiesSet();
        final Scheduler scheduler = schedulerFactoryBean.getScheduler();
        scheduler.start();
        return scheduler;
    }
}

```

## 执行Job类


```java
@Slf4j
public class ExecutionJob extends QuartzJobBean {

    private final static ExecutorService EXECUTOR_SERVICE = Executors.newWorkStealingPool();

    @Override
    protected void executeInternal(JobExecutionContext context) throws JobExecutionException {

        final QuartzJob quartzJob = (QuartzJob) context.getMergedJobDataMap().get(QuartzConfig.JOB_KEY);

        final QuartzManager quartzManager = SpringContextHolder.applicationContext.getBean(QuartzManager.class);

        try {
            final QuartzRunnable quartzRunnable
                    = new QuartzRunnable(quartzJob.getBeanName(), quartzJob.getMethodName(), quartzJob.getParams());

            final Future<Object> future = EXECUTOR_SERVICE.submit(quartzRunnable);
            future.get();
        } catch (Exception e) {
            log.error("任务执行出错", e);
            if (quartzJob.getPauseAfterFailure() != null && quartzJob.getPauseAfterFailure()) {
                quartzJob.setIsPause(false);
                quartzManager.updateIsPause(quartzJob);
            }
        }
    }
}
```

## 数据库Job类

```java
@Data
@Accessors(chain = true)
public class QuartzJob {
    private Integer id;

    private String uuid;

    private String jobName;

    private String beanName;

    private String methodName;

    private String params;

    private String cronExpression;

    private String subTask;

    private Boolean isPause;

    private Boolean pauseAfterFailure;
}
```

## 自定义任务

```java
@Slf4j
public class QuartzRunnable implements Callable<Object> {

    private final Object target;
    private final Method method;
    private final String params;

    public QuartzRunnable(String beanName, String methodName, String params) throws NoSuchMethodException {
        this.target = SpringContextHolder.applicationContext.getBean(beanName);
        this.params = params;

        if (StringUtils.hasText(params)) {
            this.method = this.target.getClass().getDeclaredMethod(methodName, String.class);
        } else {
            this.method = this.target.getClass().getDeclaredMethod(methodName);
        }
    }


    @Override
    public Object call() throws Exception {
        log.debug("定时任务开始执行, " + this);
        method.setAccessible(true);
        Object res;
        if (StringUtils.hasText(params)) {
            res = method.invoke(target, params);
        } else {
            res = method.invoke(target);
        }
        log.debug("定时任务执行完成, " + this);
        return res;
    }

    @Override
    public String toString() {
        return "QuartzRunnable{" +
                "target=" + target +
                ", method=" + method +
                ", params='" + params + '\'' +
                '}';
    }
}
```

## 任务操作类

```java
@Slf4j
@Component
@RequiredArgsConstructor
public class QuartzManager {
    private final Scheduler scheduler;

    public void addJob(QuartzJob quartzJob) {
        final JobDetail jobDetail = JobBuilder.newJob(ExecutionJob.class)
                .withIdentity(QuartzConfig.JOB_NAME + quartzJob.getId())
                .build();

        final CronTrigger cronTrigger = TriggerBuilder.newTrigger()
                .withIdentity(QuartzConfig.JOB_KEY + quartzJob.getId())
                .startNow()
                .withSchedule(CronScheduleBuilder.cronSchedule(quartzJob.getCronExpression()))
                .build();

        cronTrigger.getJobDataMap().put(QuartzConfig.JOB_KEY, quartzJob);

        ((CronTriggerImpl) cronTrigger).setStartTime(new Date());

        try {
            scheduler.scheduleJob(jobDetail, cronTrigger);
        } catch (SchedulerException e) {
            log.error("创建定时任务失败", e);
        }
    }

    public void updateIsPause(QuartzJob quartzJob) {
        // 如果是暂停状态就恢复
        if (quartzJob.getIsPause()) {
            resumeJob(quartzJob);
            quartzJob.setIsPause(false);
        } else { // 是运行状态就暂停
            pauseJob(quartzJob);
            quartzJob.setIsPause(true);
        }
    }

    /**
     * 恢复job
     *
     * @param quartzJob
     */
    public void resumeJob(QuartzJob quartzJob) {
        try {
            final TriggerKey triggerKey = TriggerKey.triggerKey(QuartzConfig.JOB_NAME + quartzJob.getId());
            final Trigger trigger = scheduler.getTrigger(triggerKey);
            final JobKey jobKey = JobKey.jobKey(QuartzConfig.JOB_NAME + quartzJob.getId());
            scheduler.resumeJob(jobKey);
        } catch (SchedulerException e) {
            log.error("恢复job失败", e);
        }
    }

    /**
     * 暂停job
     *
     * @param quartzJob
     */
    public void pauseJob(QuartzJob quartzJob) {
        final JobKey jobKey = JobKey.jobKey(QuartzConfig.JOB_NAME + quartzJob.getId());
        try {
            scheduler.pauseJob(jobKey);
        } catch (SchedulerException e) {
            log.error("暂停任务失败", e);
        }
    }

    public void removeJob(QuartzJob quartzJob) {
        try {
            final JobKey jobKey = JobKey.jobKey(QuartzConfig.JOB_NAME + quartzJob.getId());
            scheduler.pauseJob(jobKey);
            scheduler.deleteJob(jobKey);
        } catch (SchedulerException e) {
            log.error("删除任务失败", e);
        }
    }
}
```