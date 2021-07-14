package com.lcw.jwt_1.util;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;

import java.util.Base64;
import java.util.Calendar;
import java.util.Date;
import java.util.Optional;

public class JwtUtils {
    private static String secret = "jijdw_23*&&@#Lkjjh@!__==++1";

    /*public static String createToken(String userName) {
        Calendar c = Calendar.getInstance();
        c.setTime(new Date());
        c.add(Calendar.DAY_OF_MONTH, 20);
        String token = Jwts.builder()
                .setSubject(userName)
                .setExpiration(c.getTime())
                .signWith(SignatureAlgorithm.HS256, secret)
                .compact();
        return token;
    }*/

    public static String createToken(String subject) {
        Calendar c = Calendar.getInstance();
        Date issueDate = new Date();
        c.setTime(issueDate);
        c.add(Calendar.DAY_OF_MONTH, 20);
        String compactJwt = Jwts.builder()
                .setSubject(subject)
                .setIssuedAt(issueDate)
                .setExpiration(c.getTime())
                .signWith(SignatureAlgorithm.HS256, secret)
                .compact();
        return compactJwt;
    }

    public static Optional<String> parseToken(String token) {
        Claims body = Jwts.parser()
                .setSigningKey(secret)
                .parseClaimsJws(token)
                .getBody();
        if (body != null) {
            return Optional.of(body.getSubject());
        }
        return Optional.empty();
    }

    public static void main(String[] args) {
//        String token = JwtUtils.getToken("uid=1,role=admin,price=992", new Date());
        String token = "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1aWQ9MSxyb2xlPWFkbWluLHByaWNlPTk5MiIsImlhdCI6MTYyNjI0NDQ4MywiZXhwIjoxNjI3OTcyNDgzfQ.-UsOLCprH7ckcQqz63Kiiq_gkZTFewFq1AWJh-0Z4K8";
        System.out.println("加密算法: " + new String(Base64.getDecoder().decode("eyJhbGciOiJIUzI1NiJ9")));
        System.out.println("信息体: " + new String(Base64.getDecoder().decode("eyJzdWIiOiJ1aWQ9MSxyb2xlPWFkbWluLHByaWNlPTk5MiIsImlhdCI6MTYyNjI0NDQ4MywiZXhwIjoxNjI3OTcyNDgzfQ")));
    }
}