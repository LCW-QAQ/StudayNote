# 网约车-API

## api-passenger

| url                  | param                                 | describe |
| :------------------- | ------------------------------------- | -------- |
| sms/verify-code/send | {  <br />	"phoneNumber": "12345678912" <br />} | 发送验证码 |

## service-verification-code

| url                                           | param | describe           |
| --------------------------------------------- | ----- | ------------------ |
| verify-code/generate/{identity}/{phoneNumber} |       | 根据身份生成验证码 |

## service-sms

| url               | param                                                        | describe |
| ----------------- | ------------------------------------------------------------ | -------- |
| send/sms-template | {  <br />    "receivers": ["12345678912", ...], <br />    "data": [  <br />        {  <br />            "id": "SMS 14123121",   <br />            "templateMap": {  <br />            "code": "0189829"  <br />            }<br />        }  <br />    ]<br />} |          |
|                   |                                                              |          |

