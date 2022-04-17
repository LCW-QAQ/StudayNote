# Elasticsearch7_16新JavaApi简单Demo

```java
@SpringBootTest
class EsSpringbootDemoApplicationTests {

    @Autowired
    ProductService productService;

    @Autowired
    ImsAutopartsCarTypeService carTypeService;

    static final ElasticsearchClient client;

    static final Sniffer sniffer;

    static {
        // 失败后触发sniffer的监听器
        final SniffOnFailureListener sniffOnFailureListener = new SniffOnFailureListener();
        final RestClient restClient = RestClient.builder(HttpHost.create("localhost:9200"))
                .setFailureListener(sniffOnFailureListener)
                .build();

        sniffer = Sniffer.builder(restClient)
                .setSniffIntervalMillis(5000) // 每间隔5s sniffer一次
                .setSniffAfterFailureDelayMillis(30000) // 失败后延迟30s sniffer
                .build();

        sniffOnFailureListener.setSniffer(sniffer);

        client = new ElasticsearchClient(new RestClientTransport(
                restClient,
                new JacksonJsonpMapper()
        ));
    }

    @Test
    @SneakyThrows
    void contextLoads() {
//        mysqlCarTypeData2Es();
//        queryGroupByBrand();
        queryScroll();
    }

    /**
     * 将mysql中的数据导入到es中
     */
    @SneakyThrows
    void mysqlCarTypeData2Es() {
        final List<ImsAutopartsCarType> carTypes = carTypeService.list();
        List<BulkOperation> bulkOps = new ArrayList<>();
        for (ImsAutopartsCarType carType : carTypes) {
            // 批量插入
            bulkOps.add(
                    BulkOperation.of(opt -> opt.create(
                            create -> create.id(carType.getId().toString())
                                    .document(carType)
                    ))
            );
        }
        final BulkResponse resp = client.bulk(
                bulk -> bulk.index("car_type").operations(bulkOps)
        );
        System.out.println(resp);
        System.out.println(resp.errors());
    }

    /**
     * 查询每个品牌有多少种车辆，以及他们在总车辆中的占比
     */
    @SneakyThrows
    void queryGroupByBrand() {
        final SearchResponse<Object> resp = client.search(
                search -> search.index("car_type")
                        .aggregations("group_by_brand_info",
                                // 根据品牌id分组
                                agg1 -> agg1.terms(terms ->
                                                terms.size(1000)
                                                        .field("brandId"))
                                        .aggregations("brand_count",
                                                // 每个品牌车辆类型的数量
                                                agg2 -> agg2.valueCount(count -> count.field("id"))
                                        )
                        ).aggregations("count_of_car_type",
                                // 所有类型的车辆
                                agg1 -> agg1.valueCount(count -> count.field("id"))
                        )
                        .size(0),
                Object.class
        );
        final Map<String, Aggregate> agg = resp.aggregations();
        final Buckets<LongTermsBucket> buckets = agg.get("group_by_brand_info").lterms().buckets();
        final double count = agg.get("count_of_car_type").valueCount().value();
        System.out.println(count);
        AtomicLong cnt = new AtomicLong();
        buckets.array().forEach(item -> {
            final long brandCount = (long) item.aggregations().get("brand_count").valueCount().value();
            System.out.printf("%s=%d %.7f%%%n", item.key(), brandCount, brandCount / count);
            cnt.addAndGet(brandCount);
        });
        System.out.println(cnt.get());
    }

    /**
     * scroll滚动查询，防止DeepPaging
     */
    @SneakyThrows
    void queryScroll() {
        final SearchResponse<Object> resp = client.search(
                search -> search.index("car_type")
                        // 根据id排序
                        .sort(sort -> sort.field(f -> f.field("id").order(SortOrder.Asc)))
                        // 每页2条
                        .from(0).size(100)
                        // scroll游标有30s的声明周期，每次scroll查询都要指定，不然就直接失效了
                        .scroll(scroll -> scroll.time("30s")),
                Object.class
        );
        resp.hits().hits().forEach(item -> System.out.println(item.source()));
        final String sid = resp.scrollId();
        System.out.println(sid);
        // 第二次使用scroll游标
        final ScrollResponse<Object> resp2 = client.scroll(scroll -> scroll
                .scroll(s -> s.time("30s")).scrollId(sid), Object.class);
        resp2.hits().hits().forEach(item -> System.out.println(item.source()));
        System.out.println(resp2.scrollId());
    }

    @SneakyThrows
    void create() {
        DateTimeFormatter dtf = DateTimeFormatter.ofPattern("yyyy-MM-dd");
        final List<Product> products = productService.list();
        List<BulkOperation> opsList = new ArrayList<>();
        for (Product product : products) {
            final String datetime = dtf.format(LocalDateTime.ofInstant(product.getCreateTime().toInstant(),
                    ZoneId.systemDefault()));
            opsList.add(new BulkOperation.Builder()
                    .create(create -> create.id(product.getId())
                            // 定义自己的映射，这里主要是为了处理tags与自定义date格式
                            // es默认使用timestamp的方式保存Date
                            .document(/*product*/new HashMap<>() {{
                                put("name", product.getName());
                                put("desc", product.getDesc());
                                put("price", product.getPrice());
                                put("tags", product.getTags().split(","));
                                put("createTime", datetime);
                            }})
                    )
                    .build());
        }
        // 批量操作
        final BulkResponse resp = client.bulk(bulk ->
                bulk.index("my_product")
                        .operations(opsList)
        );
    }

    /**
     * 根据2022年的月份分组查询每个月销售出的手机销量与总销售金额
     */
    @SneakyThrows
    void query() {
        final SearchResponse<Object> resp = client.search(search ->
                        search.index("my_product")
                                .postFilter(postFilter ->
                                                // 查询2022年的数据
                                                postFilter.range(range ->
                                                        range.field("createTime")
                                                                .from(JsonData.of("2022-01-01"))
                                                                .to(JsonData.of("2022-12-31"))
                                                )
                                        // 根据2022年的月份分组查询每个月销售出的手机销量与总销售金额
                                ).aggregations("month_of_sales_and_total_amount",
                                        agg -> agg.dateHistogram(dateHis ->
                                                        dateHis.field("createTime")
                                                                // 根据月份分组
                                                                .calendarInterval(CalendarInterval.Month))
                                                .aggregations("month_of_sales",
                                                        // 每月总销量
                                                        agg2 -> agg2.valueCount(valueCount ->
                                                                valueCount.field("price")))
                                                .aggregations("month_of_total_amount",
                                                        // 每月总销售金额
                                                        agg2 -> agg2.sum(sum -> sum.field("price")))
                                ).size(0),
                Object.class);
        resp.hits().hits().forEach(hit -> {
            System.out.println(hit.source());
        });
        resp.aggregations().forEach((key, agg) -> {
            final Buckets<DateHistogramBucket> buckets = agg.dateHistogram().buckets();
            buckets.array().forEach(bucket -> {
                System.out.println("month_of_sales: " +
                        bucket.aggregations().get("month_of_sales").valueCount().value());
                System.out.println("month_of_total_amount: " +
                        bucket.aggregations().get("month_of_total_amount").sum().value());
                System.out.println();
            });
        });
    }

    @SneakyThrows
    void delete() {
        // 删除索引，需要删除数据直接client.delete即可
        final DeleteIndexResponse resp = client.indices().delete(delete -> delete.index("my_product"));
    }
}
```

## Sniffer

sniffer嗅探器

只需配置一个地址，自动扫描集群中所有的节点，并在节点故障时自动切换restClient连接的节点

## DeepPaging

深度分页问题

我们有6w条数据，现在要取第20000-20100条数据。由于es是分布式存储的，我们无法保证所需要的数据是存储到那个分片上，因此只能将所有分片的前20100数据取到（我们能保证每个分片的顺序），然后再将这些结果汇总排序后再取20000-20100。显然这样做性能是很低的，尤其是在分页页码巨大时，每次都要从所有分片去到前N条结果再做处理性能极低。

如果还不理解，我再举个例子用来类比：从保存了世界所有国家短跑运动员成绩的索引中查询短跑世界前三，每个国家类比为一个分片的数据，每个国家都会从国家内选出成绩最好的前三位参加最后的竞争，从每个国家选出的前三名放在一起再次选出前三名，此时才能保证是世界的前三名。

为了解决上述问题，es提供了scroll查询，scroll类似数据库游标，查询后返回一个只能向后的游标，他可以记录查询到哪里了，下一次带上scroll_id直接查询接下来的数据，而不需要再去每个分片中取数据。