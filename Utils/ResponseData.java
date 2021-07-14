package com.lcw.jwt_1.util;

public class ResponseData {
    private String code;
    private String msg;
    private Object data;

    public ResponseData() {
    }

    public ResponseData(String code, String msg, Object data) {
        this.code = code;
        this.msg = msg;
        this.data = data;
    }

    public static class ResponseDataBuilder {
        private String code;
        private String msg;
        private Object data;

        public ResponseDataBuilder() {
        }

        public void code(String code) {
            this.code = code;
        }

        public String code() {
            return this.code;
        }

        public void msg(String msg) {
            this.msg = msg;
        }

        public String msg() {
            return this.msg;
        }

        public void data(Object data) {
            this.data = data;
        }

        public Object data() {
            return this.data;
        }

        public ResponseData build() {
            return new ResponseData(this.code, this.msg, this.data);
        }
    }

    public String getCode() {
        return code;
    }

    public void setCode(String code) {
        this.code = code;
    }

    public String getMsg() {
        return msg;
    }

    public void setMsg(String msg) {
        this.msg = msg;
    }

    public Object getData() {
        return data;
    }

    public void setData(Object data) {
        this.data = data;
    }

    public static ResponseDataBuilder builder() {
        return new ResponseDataBuilder();
    }

    public static ResponseData ok(String msg, Object data) {
        return new ResponseData("200", msg, data);
    }

    public static ResponseData newInstance(String code, String msg, Object data) {
        return new ResponseData(code, msg, data);
    }
}
