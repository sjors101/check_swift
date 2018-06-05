# check_swift
 Returns average time of downloading multiple documents from swift. Using the swift API.
 
 ### Installation
 
 Pull this script:

```sh
$ git clone https://github.com/sjors101/check_swift.git
```
 
 Install the swift client with PIP:
```sh
$ sudo pip install python-swiftclient
```
 
 ### Bug info

In some cases, when the swift container contains a huge amount of documents, this script will to long to report back. This can be solved by staticly download some objects. The following code needs to be changed:

Find the following line:
```sh
reading_objects() {
    SWIFT_DOCS=($(swift --os-auth-url $OS_AUTH_URL --os-username $OS_USERNAME --os-password $OS_PASSWORD --os-tenant-name $OS_TENANT_NAME list $SWIFT_CONTAINER | head -$1 | sed 's/:.*//'))
```
And replace with static objects:
```sh
reading_objects() {
    #SWIFT_DOCS=($(swift --os-auth-url $OS_AUTH_URL --os-username $OS_USERNAME --os-password $OS_PASSWORD --os-tenant-name $OS_TENANT_NAME list $SWIFT_CONTAINER | head -$1 | sed 's/:.*//'))
    SWIFT_DOCS=("object_1.pdf" "object_2.pdf" "object_3.pdf" "object_4.pdf" "object_5.pdf" "object_6.pdf")
    SWIFT_DOCS=("${SWIFT_DOCS[@]:0:$1}")
```
