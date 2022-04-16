# Elasticsearch7_16新JavaApi简单Demo

```java
@SpringBootTest
class EsSpringbootDemoApplicationTests {

    @Autowired
    ProductService productService;

    static ElasticsearchClient client = new ElasticsearchClient(new RestClientTransport(
            RestClient.builder(HttpHost.create("localhost:9200")).build(),
            new JacksonJsonpMapper()
    ));

    @Test
    @SneakyThrows
    void contextLoads() {
        // create与query与delete一起运行有可能查询不到结果，可能是延迟或者缓存等问题
        // 分开运行后create与query就行了
//        create();
        query();
//        delete();
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

/*
# 数据库的数据，日期请自定义
productService.saveBatch(
                List.of(
                        new Product().setName("xiaomi shou ji")
                                .setDesc("xiaomi de xin shou ji")
                                .setPrice(2999.0)
                                .setTags("xingjiabigao"),
                        new Product().setName("nfc phone")
                                .setDesc("xiaomi nfc phone")
                                .setPrice(1300.0)
                                .setTags("xingjiabigao"),
                        new Product().setName("xiaomi erji")
                                .setDesc("erji zhong de huangmenji")
                                .setPrice(2222.0)
                                .setTags("xingjiabigao"),
                        new Product().setName("xiaomi phone")
                                .setDesc("shouji zhong de zhandouji")
                                .setPrice(3299.0)
                                .setTags("xingjiabigao")
                        )
        );
*/
```