# Spring源码

## IOC

### IOC源码概览

#### 从简单Demo理解spring的流程

使用spring框架时我们会配置xml, spring从xml加载bean对象, 这是最简单的demo

将上述操作在源码中可以简述为:

```mermaid
graph LR
loadXml[加载xml] --> resolveXml[解析xml]
				--> beanDefinition[封装beanDefinition]
				--> instantiate[实例化bean]
				--> addToIoc[存入容器]
				--> getFromIoc[从容器中获取]	
```

#### 源码流程图

> 核心逻辑就是refresh方法

```mermaid
graph TB
%% 主流程
设置配置文件路径与系统环境变量 --> refresh[refresh<br>IOC容器, 这里就是IOC容器的核心操作]
	--> prepareRefresh[prepareRefresh<br>刷新前的准备操作]
	--> obtainFreshBeanFactory[obtainFreshBeanFactory<br>获取新的bean对象工厂]
	--> prepareBeanFactory[prepareBeanFactory<br>为beanFactory做准备]
	--> postProcessBeanFactory[beanFactoryPostProcessor<br>默认空实现用于扩展]
	--> invokeBeanFactoryPostProcessors[invokeBeanFactoryPostProcessors<br>执行beanFactoryPostProcessor<br>使用多个循环分开处理有序与无序postProcessor]
	--> registerBeanPostProcessors[registerBeanPostProcessors<br>注册beanPostProcessor<br>同样使用多个循环分开处理有序与无序postProcessor]
	--> initMessageSource[initMessageSource<br>国际化操作]
	--> initApplicationEventMulticaster[initApplicationEventMulticaster<br>初始事件广播器]
	--> onRefresh[onRefresh<br>初始化特定的bean对象, 用于扩展<br>例如spring mvc会在这里创建servlet服务器]
	--> registerListeners[registerListeners<br>初始化监听器]
	--> finishBeanFactoryInitialization[finishBeanFactoryInitialization<br>实例化所有非懒加载的单例bean]
	--> finishRefresh[finishRefresh<br>最后一步发布相应的事件]

%% 主流程INFO
obtainFreshBeanFactory__INFO(创建DefaultListableBeanFactory对象<br>加载Xml配置信息即loadBeanDefinitions<br>配置会被加载到DefaultListableBeanFactory的beanDefinitionMap中) --> obtainFreshBeanFactory

prepareRefresh__INFO(记录容器启动时间<br>容器运行状态<br>验证环境变量等) --> prepareRefresh

prepareBeanFactory__INFO(配置标准上下文例如ClassLoder与BeanPostProcessor) --> prepareBeanFactory

finishBeanFactoryInitialization__INFO(finishBeanFactoryInitialization<br>实例化的具体流程) --> finishBeanFactoryInitialization
finishBeanFactoryInitialization__INFO --> preInstantiateSingletons[preInstantiateSingletons<br>开始实例化, 遍历beanNames]
	--> getBean[getBean<br>无论是FactoryBean还是普通Bean都会走这个方法]
	--> doGetBean[doGetBean<br>真正获取bean的方法]
	--> getSingleton_first[第一次getSingleton<br>尝试从IOC容器中获取单例对象]
	--> getSingleton_second[第二次getSingleton<br>调用String, ObjectFactory重载]
	--> createBean[createBean<br>调用doCrateBean]
	--> doCreateBean[doCreateBean<br>具体创建bean对象<br>通过反射创建对象]
	
finishRefresh__INFO(完成刷新操作发布相应事件) --> finishRefresh
finishRefresh__INFO --> clearResourceCaches[clearResourceCaches<br>清楚上下文缓存, 例如ASM元数据]
					--> initLifecycleProcessor[initLifecycleProcessor<br>初始化生命周期处理器]
					--> getLifecycleProcessor_onRefresh[getLifecycleProcessor_onRefresh<br>回调生命周期处理器的onRefresh事件]
					--> publishEvent[publishEvent<br>获取事件广播器并发布事件]
					--> resetCommonCaches[resetCommonCaches<br>清除通用缓存<br>例如反射缓存, 注解缓存等]
```

### SpringBean生命周期

```mermaid
graph TB
instantiation_BeanFactoryPostProcessor[实例化BeanFactoryPostProcessor] --> invoke_BeanFactoryPostProcessor_postProcessBeanFactory[执行BeanFactoryPostProcessor#postProcessBeanFactory]
	--> instantiation_BeanPostProcessor[实例化BeanPostProcessor]
	--> instantiation_InstantiationAwareBeanPostProcessorAdapter[实例InstantiationAwareBeanPostProcessorAdapter]
	--> 执行InstantiationAwareBeanPostProcessor的postProcessBeforeInstantiation方法
	--> 执行构造器即创建实例
	--> 执行InstantitationAwareBeanPostProcessor的postProcessAfterInstantiation方法
	--> bean的属性注入
	--> 调用BeanNameAware的setBeanName
	--> 调用BeanFactoryAware的setBeanFactory
	--> 执行BeanPostProcessor的postProcessBeforeInitialization
	--> 调用InitailizingBean的afterPropertiesSet
	--> 调用init-method
	--> 执行BeanPostProcessor的postProcessAfterInitialization
	--> 执行InstantiationAwareBeanPostProcessor的postProcessAfterInitialization
	--> 销毁容器
	--> 调用DisposibleBean的destroy
	--> 调用destroy-method
```





### Spring 源码流程

> 以ClassPathXmlApplicationContext为列

```java
public ClassPathXmlApplicationContext(
    String[] configLocations, boolean refresh, @Nullable ApplicationContext parent)
    throws BeansException {
	// 调用父类构造器, 初始化全局属性.
    // 例如容器状态标识active, 全局唯一id, 全局ioc锁等
    super(parent);
    // 设置配置文件路径, 初始化Enviroment对象(存储环境变量, 系统环境变量与用户给定的环境变量)
    setConfigLocations(configLocations);
    if (refresh) {
        // IOC核心逻辑
        refresh();
    }
}
```

#### super

调用父类构造器, 创建全局属性, 全局唯一id, 初始化资源解析器(解析Ant-Style风格的模式), 并设置父容器

```mermaid
graph TB
ClassPathXmlApplicationContext --> AbstractXmlApplicationContext
			--> AbstractRefreshableConfigApplicationContext
			--> AbstractApplicationContext[AbstractApplicationContext<br>主要的初始化都在这里]
AbstractApplicationContext__INFO(初始化全局属性<br>例如容器状态标识active, 全局唯一id, 全局ioc锁等) --> AbstractApplicationContext
AbstractApplicationContext__INFO --> getResourcePatternResolver
	--> PathMatchingResourcePatternResolver[PathMatchingResourcePatternResolver<br>创建Ant-Style风格的模式解析器, 用于解析Resource实例]
```

#### setConfigLocations

> 设置配置文件路径, 初始化Enviroment对象(存储环境变量, 系统环境变量与用户给定的环境变量)

```mermaid
graph TB
setConfigLocations --> setSomeVariable[设置容器启动时间<br>设置活跃状态为true<br>设置关闭状态为false]
	--> resolvePath[resolvePath<br>解析给定的路径, 如有必要, 将占位符替换为相应的环境属性值]
	--> getEnvironment[getEnvironment<br>该方法为懒加载<br>主要加载systemProperties与systemEnvironment<br>systemProperties为jvm提供的环境变量类似于-Dargs=xxx<br>systemEnvironment为系统环境变量]
	--> resolveRequiredPlaceholders
	--> doResolvePlaceholders[doResolvePlaceholders<br>解析Ant-Style风格, 替换占位符]
```

#### refresh

> IOC核心方法, 根据配置刷新整个IOC容器

##### prepareRefresh

> 为刷新上下文做准备

```mermaid
graph TB
prepareRefresh --> updateSomething[设置启动时间, 容器状态]
	--> initPropertySources[initPropertySources<br>初始化上下文`配置文件`中所有的占位符<br>默认空实现, 用于扩展, 可以在spring mvc中看到相应的扩展]
	--> getEnvironment.validateRequiredProperties[getEnvironment.validateRequiredProperties<br>验证必要参数<br>若没有必要参数则抛出MissingRequiredPropertiesException]
	--> _create_earlyApplicationListeners[创建earlyApplicationListeners监听器集合<br>该集合默认为空, 有可能有值<br>例如springboot中自动配置类会初始化一些早起的应用程序监听器]
	--> _create_earlyApplicationEvents[创建earlyApplicationEvents事件集合]
```

##### obtainFreshBeanFactory

> 刷新并获取内部的beanFactory
>
> 加载所有beanDefinition信息, Component, Service, Repository等注解也是在这里解析的

```mermaid
graph TB
obtainFreshBeanFactory --> refreshBeanFactory[refreshBeanFactory<br>刷新beanFactory]
	-->|已存在beanFactory| destroyBeans[destroyBeans<br>销毁工厂中的所有bean对象] --> closeBeanFactory[closeBeanFactory<br>关闭操作很简单, 将beanFactory与serializationId置空]
refreshBeanFactory -->|不存在beanFactory| createBeanFactory[createBeanFactory<br>创建DefaultListableBeanFactory对象<br>beanFactory实例, 包含beanDefinitionMap, 三级缓存等]
	--> customizeBeanFactory[customizeBeanFactory<br>用于扩展]
	--> loadBeanDefinitions[loadBeanDefinitions<br>根据配置文件加载beanDefinitions到beanDefinitionMap]
loadBeanDefinitions__INFO(XmlBeanDefinitionReader流程) --> loadBeanDefinitions
loadBeanDefinitions__INFO -->  XmlBeanDefinitionReader.loadBeanDefinitions[XmlBeanDefinitionReader.loadBeanDefinitions<br>通过reader读取给定一个或多个配置文件信息]
	--> doLoadBeanDefinitions
	--> registerBeanDefinitions[registerBeanDefinitions<br>注册bean信息到beanDefinitionMap]
	--> doRegisterBeanDefinitions
	--> preProcessXml
	--> parseBeanDefinitions[parseBeanDefinitions]
	--> postProcessXml
parseBeanDefinitions__INFO(根据命名空间, 解析默认标签与自定义标签beanDefinitions) --> parseBeanDefinitions
parseBeanDefinitions__INFO --> parseDefaultElement_or_parseCustomElement[parseDefaultElement_or_parseCustomElement]
	--> getNamespaceHandlerResolver#resolve[getNamespaceHandlerResolver#resolve<br>根据命名空间匹配对应的handler]
	--> handler#parse[handler#parse<br>使用命名空间处理器解析beanDefinitions]
	--> findParserForElement[findParserForElement<br>找到该命名空间下对应的element元素并返回beanDefinitionParser]
	--> beanDefinitionParser#parse[beanDefinitionParser#parse<br>进行具体解析<br>例如compoent-scan标签对应ComponentScanBeanDefinitionParser<br>通过ClassPathBeanDefinitionScanner#doScan扫描注解并添加至beanDefinitinoMap<br>同时还会注册各种BeanPostProcessor用于实例化bean解析注解]
```

##### prepareBeanFactory

> 准备beanFactory

* 设置BeanClassLoader
* bean spring el表达式解析器
* 设置PropertyEditorRegistrar, 属性处理器, 列如将字符串`A省_B市_C区`解析为Address对象
* 添加ApplicationContextAwareProcessor
* ignoreDependencyInterface忽略各种Aware生命周期接口, 后续实例化bean后会在invokeAwareMethods里执行, 这里不需要执行
* registerResolvableDependency预装配各种对象, 例如BeanFactory, ApplicationContext, ResourceLoader
* 添加ApplicationListenerDetector应用程序事件监听器BeanPostProcessor
* 初始化各种Environment, 注册到beanFactory中

##### postProcessBeanFactory

>扩展方法

## AOP

