// Copyright Project Harbor Authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

*** Settings ***
Documentation  Harbor BATs
Library  ../../apitests/python/library/Harbor.py  ${SERVER_CONFIG}
Resource  ../../resources/Util.robot
Default Tags  Replication

*** Variables ***
${HARBOR_URL}  https://${ip}
${SSH_USER}  root
${HARBOR_ADMIN}  admin
${SERVER}  ${ip}
${SERVER_URL}  https://${SERVER}
${SERVER_API_ENDPOINT}  ${SERVER_URL}/api
&{SERVER_CONFIG}  endpoint=${SERVER_API_ENDPOINT}  verify_ssl=False
${REMOTE_SERVER}  ${ip1}
${REMOTE_SERVER_URL}  https://${REMOTE_SERVER}
${REMOTE_SERVER_API_ENDPOINT}  ${REMOTE_SERVER_URL}/api

*** Test Cases ***
Test Case - Get Harbor Version
#Just get harbor version and log it
    Get Harbor Version

Test Case - Pro Replication Rules Add
    Init Chrome Driver
    Sign In Harbor    ${HARBOR_URL}    ${HARBOR_ADMIN}    ${HARBOR_PASSWORD}
    Switch To Replication Manage
    Check New Rule UI Without Endpoint
    Close Browser

Test Case - Harbor Endpoint Verification
    #This case need vailid info and selfsign cert
    Init Chrome Driver
    ${d}=    Get Current Date    result_format=%M%S
    Sign In Harbor    ${HARBOR_URL}    ${HARBOR_ADMIN}    ${HARBOR_PASSWORD}
    Switch To Registries
    Create A New Endpoint    harbor    edp1${d}    https://${ip}    ${HARBOR_ADMIN}    ${HARBOR_PASSWORD}    N
    Endpoint Is Pingable
    Enable Certificate Verification
    Endpoint Is Unpingable
    Close Browser

Test Case - DockerHub Endpoint Add
    #This case need vailid info and selfsign cert
    Init Chrome Driver
    ${d}=    Get Current Date    result_format=%M%S
    Sign In Harbor    ${HARBOR_URL}    ${HARBOR_ADMIN}    ${HARBOR_PASSWORD}
    Switch To Registries
    Create A New Endpoint    docker-hub    edp1${d}    https://hub.docker.com/    danfengliu    Aa123456    Y
    Close Browser

Test Case - Harbor Endpoint Add
    #This case need vailid info and selfsign cert
    Init Chrome Driver
    ${d}=    Get Current Date    result_format=%M%S
    Sign In Harbor    ${HARBOR_URL}    ${HARBOR_ADMIN}    ${HARBOR_PASSWORD}
    Switch To Registries
    Create A New Endpoint    harbor    testabc    https://${ip}    ${HARBOR_ADMIN}    ${HARBOR_PASSWORD}    Y
    Close Browser

Test Case - Harbor Endpoint Edit
    Init Chrome Driver
    ${d}=  Get Current Date  result_format=%m%s
    Sign In Harbor  ${HARBOR_URL}  ${HARBOR_ADMIN}  ${HARBOR_PASSWORD}
    Switch To Registries
    Rename Endpoint  testabc  deletea
    Retry Wait Until Page Contains  deletea
    Close Browser

Test Case - Harbor Endpoint Delete
    Init Chrome Driver
    ${d}=  Get Current Date  result_format=%m%s
    Sign In Harbor  ${HARBOR_URL}  ${HARBOR_ADMIN}  ${HARBOR_PASSWORD}
    Switch To Registries
    Delete Endpoint  deletea
    Delete Success  deletea
    Close Browser

Test Case - Replication Of Pull Images from DockerHub To Self
    Init Chrome Driver
    ${d}=    Get Current Date    result_format=%M%S
    #login source
    Sign In Harbor    ${HARBOR_URL}    ${HARBOR_ADMIN}    ${HARBOR_PASSWORD}
    Create An New Project    project${d}
    Switch To Registries
    Create A New Endpoint    docker-hub    e${d}    https://hub.docker.com/    danfengliu    Aa123456    Y
    Switch To Replication Manage
    Create A Rule With Existing Endpoint    rule${d}    pull    danfengliu/*    image    e${d}    project${d}
    Select Rule And Replicate  rule${d}
    Sleep    20
    Go Into Project    project${d}
    Switch To Project Repo
    #In docker-hub, under repository danfengliu, there're only 2 images: centos,mariadb.
    Retry Wait Until Page Contains    project${d}/centos
    Retry Wait Until Page Contains    project${d}/mariadb
    Close Browser

Test Case - Replication Of Push Images from Self To Harbor
    Init Chrome Driver
    ${d}=    Get Current Date    result_format=%M%S
    #login source
    Sign In Harbor    ${HARBOR_URL}    ${HARBOR_ADMIN}    ${HARBOR_PASSWORD}
    Create An New Project    project${d}
    Push Image    ${ip}    ${HARBOR_ADMIN}    ${HARBOR_PASSWORD}    project${d}    hello-world
    Push Image    ${ip}    ${HARBOR_ADMIN}    ${HARBOR_PASSWORD}    project${d}    busybox:latest
    Push Image With Tag    ${ip}    ${HARBOR_ADMIN}    ${HARBOR_PASSWORD}    project${d}    hello-world    v1
    Switch To Registries
    Create A New Endpoint    harbor    e${d}    https://${ip1}    ${HARBOR_ADMIN}    ${HARBOR_PASSWORD}
    Switch To Replication Manage
    Create A Rule With Existing Endpoint    rule${d}    push    project${d}/*    image    e${d}    project_dest${d}
    #logout and login target
    Logout Harbor
    Sign In Harbor    https://${ip1}    ${HARBOR_ADMIN}    ${HARBOR_PASSWORD}
    Create An New Project    project_dest${d}
    #logout and login source
    Logout Harbor
    Sign In Harbor    ${HARBOR_URL}    ${HARBOR_ADMIN}    ${HARBOR_PASSWORD}
    Switch To Replication Manage
    Select Rule And Replicate  rule${d}
    Sleep    20
    Logout Harbor
    Sign In Harbor    https://${ip1}    ${HARBOR_ADMIN}    ${HARBOR_PASSWORD}
    Go Into Project    project_dest${d}
    Switch To Project Repo
    Retry Wait Until Page Contains    project_dest${d}/hello-world
    Retry Wait Until Page Contains    project_dest${d}/busybox
    Close Browser

Test Case - Replication Of Push Chart from Self To Harbor
    Init Chrome Driver
    ${d}=    Get Current Date    result_format=%M%S
    #login source
    Sign In Harbor    ${HARBOR_URL}    ${HARBOR_ADMIN}    ${HARBOR_PASSWORD}
    Create An New Project    project${d}
    Go Into Project  project${d}  has_image=${false}
    Switch To Project Charts
    Upload Chart files
    Switch To Registries
    Create A New Endpoint    harbor    e${d}    https://${ip1}    ${HARBOR_ADMIN}    ${HARBOR_PASSWORD}
    Switch To Replication Manage
    Create A Rule With Existing Endpoint    rule${d}    push    project${d}/*    chart    e${d}    project_dest${d}
    #logout and login target
    Logout Harbor
    Sign In Harbor    https://${ip1}    ${HARBOR_ADMIN}    ${HARBOR_PASSWORD}
    Create An New Project    project_dest${d}
    #logout and login source
    Logout Harbor
    Sign In Harbor    ${HARBOR_URL}    ${HARBOR_ADMIN}    ${HARBOR_PASSWORD}
    Switch To Replication Manage
    Select Rule And Replicate    rule${d}
    Sleep    20
    Logout Harbor
    Sign In Harbor    https://${ip1}    ${HARBOR_ADMIN}    ${HARBOR_PASSWORD}
    Go Into Project    project_dest${d}    has_image=${false}
    Switch To Project Charts
    Go Into Chart Version    ${harbor_chart_name}
    Retry Wait Until Page Contains    ${harbor_chart_version}
    Go Into Chart Detail    ${harbor_chart_version}
    Close Browser

Test Case - Replication Of Push Images from Self To Harbor By Push Event
    Init Chrome Driver
    ${d}=    Get Current Date    result_format=%M%S
    #login source
    Sign In Harbor    ${HARBOR_URL}    ${HARBOR_ADMIN}    ${HARBOR_PASSWORD}
    Create An New Project    project${d}
    Switch To Registries
    Create A New Endpoint    harbor    e${d}    https://${ip1}    ${HARBOR_ADMIN}    ${HARBOR_PASSWORD}
    Switch To Replication Manage
    Create A Rule With Existing Endpoint    rule${d}    push    project${d}/*    image    e${d}    project_dest${d}
    ...    Event Based
    #logout and login target
    Logout Harbor
    Sign In Harbor    https://${ip1}    ${HARBOR_ADMIN}    ${HARBOR_PASSWORD}
    Create An New Project    project_dest${d}
    Push Image    ${ip}    ${HARBOR_ADMIN}    ${HARBOR_PASSWORD}    project${d}    centos
    Sleep  10
    Go Into Project    project_dest${d}
    Switch To Project Repo
    Retry Wait Until Page Contains    project_dest${d}/centos
    Close Browser