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
>
> 解析出来的beanDefinition包含各种定义信息, 例如AnnotatedBeanDefinition加了注解的bean,  ScannedGenericBeanDefinition同样是加了注解的bean是AnnotatedBeanDefinition的子类, AbstractBeanDefinition普通的没有其他Spring注解修饰列如@ComponentScan

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

##### invokeBeanFactoryPostProcessors

> 执行beanFactoryPostProcessors, 优先执行有顺序的即被Ordered或PriorityOrdered标记的, 最后执行没有顺序的
>
> 如果beanFactory instanceof BeanDefinitionRegistry, 那么会先执行BeanDefinitionRegistryPostProcessor, 仍然是优先执行Ordered或PriorityOrdered, 最后执行没有顺序的
>
> 执行流程中主要有三类BeanFactoryPostProcessor:
>
> * 用户手动加入的BeanFactoryPostProcessor
>     * 配置文件中定义的
>     * 调用addBeanFactoryPostProcessor
> * 实现了BeanDefinitionRegistryPostProcessor接口
> * 实现了BeanFactoryPostProcessor接口

```mermaid
graph TB
invokeBeanFactoryPostProcessors -->|对BeanDefinitionRegistry的子类特殊处理| invokeSortBeanDefinitionRegistryPostProcessor[先执行PriorityOrdered修饰, 然后执行Ordered修饰]
	--> invokeNonSortBeanDefinitionRegistryPostProcessor[执行没有顺序的BeanDefinitionRegistryPostProcessor]
invokeBeanFactoryPostProcessors -->|普通的BeanFactoryPostProcessor| invokeSortBeanFactoryPostProcessor[先执行PriorityOrdered修饰, 然后执行Ordered修饰]
	--> invokeNonSortBeanFactoryPostProcessor[执行没有顺序的BeanFactoryPostProcessor]
```

###### ConfigurationClassPostProcessor

> 在开启compoent-scan时, 该方法会注册一个ConfigurationClassPostProcessor实现了BeanDefinitionRegistryPostProcessor接口
>
> 用于处理@Compoent以及子注解修饰的类的其他注解信息, @Import, @CompoentScan, @ImportResource等

## AOP

没有依赖的AOP:

1. A对象需要被代理
    - 普通bean对象aop, 是在bean对象被实例化且属性填充完成后, 通过BeanPostProcessor子类InstantiationAwareBeanPostProcessor子类AnnotationAwareAspectJAutoProxyCreator#postProcessAfterInitialization来处理, 返回代理bean对象

有依赖的AOP, 以有依赖循环为例(这种情况最复杂), 有三种情况:

1. A依赖B, A是非代理bean B是需要代理的bean

    - 先创建A, A被加入singeltonFactories
    - 在populate属性填充时, 依赖B, 则创建B对象
    - B对象是代理对象, 依赖于A, getSingelton(A), 从singletonFactories获取A对象的早期引用即AbstractAutowireCapableBeanFactory#getEarlyBeanReference, 由于A对象无需代理, 直接返回之前创建好的A对象(此时属性还未填充完毕), 并将A对象存入earlySingletonObjects. 此时A对象属性还未填充, 需要等待B对象创建完成
    - B属性填充后, 走普通Bean对象代理流程
    - 返回被代理的B对象, 填充A
    - 最后A对象被创建完毕

2. A依赖B, A是需要代理的bean, B是非代理bean

    - 先创建A, A被加入singeltonFactories

    - 在populate属性填充时, 依赖B, 则创建B对象

    - B对象依赖于A, getSingleton(A), 从singletonFactories获取A对象的早期引用即AbstractAutowireCapableBeanFactory#getEarlyBeanReference, 由于A对象需要被代理, 会由AnnotationAwareAspectJAutoProxyCreator创建代理对象, 存入earlySingletonObjects, 然后返回给B对象

        - ```java
            protected Object getEarlyBeanReference(String beanName, RootBeanDefinition mbd, Object bean) {
               Object exposedObject = bean;
               if (!mbd.isSynthetic() && hasInstantiationAwareBeanPostProcessors()) {
                  for (SmartInstantiationAwareBeanPostProcessor bp : getBeanPostProcessorCache().smartInstantiationAware) {
                     exposedObject = bp.getEarlyBeanReference(exposedObject, beanName);
                  }
               }
               return exposedObject;
            }
            ```

    - B对象属性填充完毕, 返回给A

    - A对象属性填充完毕, 走普通Bean对象代理流程, 但是由于之前生成了A对象向的代理, 此时应该在earlySingletonObjects中, 所以这里不会再次创建代理对象了

    - A对象会在执行玩initializeBean(即执行awre方法与beanPostProcessor后), 再次getSingleton, 获取earlySingletonObjects存储的代理A对象, 将代理A对象返回

        - ```java
            // class AbstractAutowireCapableBeanFactory
            protected Object doCreateBean(String beanName, RootBeanDefinition mbd, @Nullable Object[] args)
                  throws BeanCreationException {
                
               // 省略...
              
               // 填充属性与执行声明周期接口和BeanPostProcessor
            
               // 允许早期引用
               if (earlySingletonExposure) {
                   // 由于A对象在B依赖A时, 被创建且是代理bean
                  Object earlySingletonReference = getSingleton(beanName, false);
                   // 能从earlySingletonObjects中获取到代理A对象
                  if (earlySingletonReference != null) {
                     if (exposedObject == bean) {
                         // 将返回的对象设为代理A对象
                        exposedObject = earlySingletonReference;
                     }
                     else if (!this.allowRawInjectionDespiteWrapping && hasDependentBean(beanName)) {
                        // 省略...
                     }
                  }
               }
               // 省略...
               return exposedObject;
            }
            ```
        
    - 最后A对象创建完毕
    
3. A依赖B, AB都是需要代理的bean

    - 同上
