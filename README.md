<h1 style="text-align: center;">Decaf: A Centralized Configuration Management Platform for Distributed Systems</h1>

# Usage

## Sync with xxl-conf
```
#synchronize submodule xxl-conf with xxl's github repo
git submodule update --init --recursive
```

## Start / Shutdown
```
npm start
npm stop
```


# Introduction

Decaf is a centralized configuration management platform for distributed systems. Decaf is designed to manage the configurations of multiple projects in a centrailized way, and meanwhile the managed systems can work in a distributed way across the Internet environment.

# Background

In our current backend software development, Our services will always rely on some configuration to work properly, these configuration information usually includes: jdbc arguments, redis address, activity or function switch, threshold values, black-and-white-list, dependency endpoint, credientials, etc.

## Why not .properties or .env

Usually developers will store the above configuration in .properties files under resource directory(Java Project) or .env files(NodeJS project), which will lead to the following problems:

1. manual modification of .properties/.env files will require special development knowledge and easy to make mistakes;
1. re-build & re-package software after configuration changed;
1. restart service after configuration changed(when operating online cluster services, this will drive ops-team crazy);
1. configuration update will suffer from a significant delay because of the above cumbersome process;
1. configuration spreads into different services and will become increasingly difficult to maintain when project has multiple deploy environment(develop/staging/production) where configurations vary with each other.

## Why Decaf

1. No manual modification on configuration files: In configuration certer, an friendly user-interface will help ops locate the configuration of a service, input the new value and update the cconfiguration of that service. All services across multiple projects can be managed in this centralized and efficient way.
1. No need to re-build or re-package source code after configuration changed. New configuration will be pushed to the service in realtime.
1. no need to restart service to make new configuration take effect.
1. Configuration change will suffer no delay. New configuration will be pushed to service and take effect at the same time when you click the update button in configuration center. This is critical for those of switch configurations. The efficiency improvement is significant comparing to the traditional find-file-modification-rebuild-restart way.
1. Best practise for the One-Package-for-All-Environments. As all the configuration for different deploy environments are stored & managed in configuration center, one binary package can be reused in develop/staging/production environments.

# Technology Bases

## ZK: Apache ZooKeeper

https://zookeeper.apache.org/

Apache ZooKeeper is essentially a centralized service for distributed systems to a hierarchical key-value store, which is used to provide a distributed configuration service, synchronization service, and naming registry for large distributed systems. ZooKeeper was a sub-project of Hadoop but is now a top-level Apache project in its own right.

![](https://static.oschina.net/uploads/img/201609/22154508_PeVb.jpg)

ZooKeeper use a tree structure to store syncronized data which can be used to coordinate distributed application's data syncronization with very high performance. Typically, ZK can be used in the following circumstances:

- Naming Service
Accquiring resource or service endpoint by a specific name. The global uniqueness of the naming can be guaranteed.

- Configuration Management & Notification system
Storing configuration into a directory node of ZooKeeper, Keeping all applied services watching the status of that node, will make services get notified when configuration updated. Geting new configuration from ZooKeeper will enable configuratoin shared and synchronized in a distributed way.

- Synchronization
A solution to confliction access to distributed resources.

- Group Service & Leader Election

![](https://static.oschina.net/uploads/img/201609/22153843_o7SQ.jpg)

Multiple servers forms a service cluster. There must be one 'leader' who knows the status of every server in this cluster. Once there is exited server going down or new server coming up, the leader must get notified and ajdust the resource allocation policy for the cluster accordingly.

## Ehcache

Ehcache is a widely used open source Java distributed cache for general purpose caching, Java EE and light-weight containers. It features memory and disk stores, replicate by copy and invalidate, listeners, cache loaders, cache extensions, cache exception handlers, a gzip caching servlet filter, RESTful and SOAP APIs. Ehcache is available under an Apache open source license and is actively supported.

In Decaf, we'll use Ehcache to cache configuration in the distributed service side.

## Node Zookeeper Client

https://github.com/alexguan/node-zookeeper-client

A pure Javascript ZooKeeper client module for Node.js to access Zookeeper.

# Architect Design

## Environment
- Zookeeper3.4+
- Mysql5.5+ or AWS DynamoDB
- Maven3+
- Jdk1.7+
- Tomcat7+

## Components Diagram
```
@startuml

database "MySql or AWS DynamoDB" {
	folder "Configuration Store/Backup" as DB {
	}
}

node "Configuration Management UI" as ADMIN {

}

cloud "ZooKeeper\nConfiguration Tree" AS ZK #PaleGreen{
	[ZK-1]
	[ZK-2]
	[ZK-3]
}

node "Service A" #cyan {
	frame "Decaf Client-API" #gold {
		frame "Ehcache" #pink {
			frame "ZK-Client" as ZK_CLIENT #PaleGreen{

			}
		}
	}
}

node "Service B" as SB #cyan{
}

node "Service C" as SC #cyan{
}


ZK --> ZK_CLIENT : puch & notification configurations
ZK --> SB
ZK --> SC

ADMIN --> ZK : add/update/delete\nconfiguration

ADMIN --> DB : store/backup configuration
DB --> ADMIN : restore configuration\nin case of ZK has broken data

@enduml
```

## ZooKeeper Cluster

1. ZK设计: 系统在ZK集群中占用一个根目录 "/conf", 每新增一条配置项, 将会在该目录下新增一个子节点。结构如下图, 当配置变更时将会触发ZK节点的变更, 将会触发对应类型的ZK广播。
1. 数据库备份配置信息: 配置信息在ZK中的新增、变更等操作, 将会同步备份到Mysql中, 进一步保证数据的安全性;
1. 配置推送: 配置推送功能在ZK的Watch机制实现。Client在加载一条配置信息时将会Watch该配置对应的ZK节点, 因此, 当对该配置项进行配置更新等操作时, 将会触发ZK的NodeDataChanged广播, Client竟会立刻得到通知并刷新本地缓存中的配置信息;

## Configuration Management User-Interface Center

Providing a Web-based Administration UI to query, insert, update, delete configuration for every project.

Configurate file location of the Adminitration UI Center

```
conf-admin.properties
```
    
Configuration Items:

```
# zookeeper cluster, using comma to seperate multiple addresses.
conf.admin.zkaddress=127.0.0.1:2181
# configuration directory in zookeeper
conf.admin.zkpath=/conf

# conf, jdbc(MySQL db or AWS DynamoDB connection)
conf.admin.jdbc.driverClass=com.mysql.jdbc.Driver
conf.admin.jdbc.url=jdbc:mysql://localhost:3306/conf?Unicode=true&amp;characterEncoding=UTF-8
conf.admin.jdbc.username=root
conf.admin.jdbc.password=root_pwd
```

### User Management UI

** Share the Users with Backend Lazybee User Management **

新增用户：点击 "新增用户" 按钮，可添加新用户，用户属性说明如下：

    - 权限：
        - 管理员：拥有配置中心所有权限，包括：用户管理、项目管理、配置管理等；
        - 普通用户：仅允许操作自己拥有权限的项目下的配置；
    - 用户名：配置中心登陆账号
    - 密码：配置中心登陆密码
    
系统默认提供了一个管理员用户和一个普通用户。
    
![输入图片说明](https://static.oschina.net/uploads/img/201803/02113403_E0cT.png "在这里输入图片标题")

分配项目权限：选中普通用户，点击右侧 "分配项目权限" 按钮，可为用户分配项目权限。拥有项目权限后，该用户可以查看和操作该项目下全部配置数据。

![输入图片说明](https://static.oschina.net/uploads/img/201803/02120028_GaLm.png "在这里输入图片标题")

修改用户密码：配置中心右上角下拉框，点击 "修改密码" 按钮，可修改当前登录用户的登录密码
（除此之外，管理员用户，可通过编辑用户信息功能来修改其他用户的登录密码）；
    
![输入图片说明](https://static.oschina.net/uploads/img/201803/02120524_syzc.png "在这里输入图片标题")

### Projects Management

系统以 "项目" 为维度进行权限控制，以及配置隔离。可进入 "配置管理界面" 操作和维护项目，项目属性说明如下：

    - AppName：每个项目拥有唯一的AppName，作为项目标示，同时作为该项目下配置的统一前缀。
    - 项目名称：该项目的名称；

系统默认提供了一个示例项目。

![输入图片说明](https://static.oschina.net/uploads/img/201803/02120951_FVt6.png "在这里输入图片标题")

### Project Configuration Management

进入"配置管理" 界面, 选择项目，然后可查看和操作该项目下配置数据。

![输入图片说明](https://static.oschina.net/uploads/img/201803/02121553_K68b.png "在这里输入图片标题")

新增配置：点击 "新增配置" 按钮可添加配置数据，配置属性说明如下：

    - KEY：配置的KEY，创建时将会自动添加所属项目的APPName所谓前缀，生成最终的Key。可通过客户端使用最终的Key获取配置；
    - 描述：该配置的描述信息；
    - VALUE：配置的值；

![输入图片说明](https://static.oschina.net/uploads/img/201803/02121602_d5ak.png "在这里输入图片标题")

至此, 一条配置信息已经添加完成；       
通过客户端可以获取该配置, 并且支持动态推送更新。 

历史版本回滚：配置存在历史变更操作时，点击右侧的 "变更历史" 按钮，可查看该配置的历史变更记录。
包括操作时间、操作人，设置的配置值等历史数据，因此可以根据历史数据，重新编辑配置并回滚到历史版本；

![输入图片说明](https://static.oschina.net/uploads/img/201803/02175944_Whz5.png "在这里输入图片标题")

## Client(Service-Side)

客户端主要分为三层:

- ZK-Client : 第一层为ZK远程客户端的封装, 当业务方项目初始化某一个用到的配置项时, 将会触发ZK-Client对该配置对应节点的Watch, 因此当该节点变动时将会监听到ZK的类似NodeDataChanged的广播, 可以实时获取最新配置信息; 
- Ehcache : 第二层为客户端本地缓存, 可以大大提高系统的并发能力, 当配置初始化或者接受到ZK-Client的配置变更时, 将会把配置信息缓存只Encache中, 业务中针对配置的查询都是读缓存方式实现, 降低对ZK集群的压力;
- Client-API : 第三层为暴露给业务方使用API, 简单易用, 一行代码获取配置信息, 同时可保证API获取到的配置信息是实时最新的配置信息;

得益于LocalCache, 因此可以放心应用在业务代码中, 不必担心并发压力。
