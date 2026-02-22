# 🚀 Windows Dev Toolkit | 开发者脚本工具箱

这是一个专为 Windows 开发者打造的轻量级自动化脚本集。旨在通过简单的命令，解决日常开发中繁琐的状态查询、进程管理及环境清理工作。

---

## 🛠️ 核心工具索引

| 脚本名称 | 功能描述 | 核心亮点 |
| :--- | :--- | :--- |
| **[`port.bat`](./scripts/port.bat)** | **端口深度溯源** | 自动提取 JVM 参数、启动类、项目路径及内存占用。 |
| *(待添加...)* | *预留位置* | *后续可添加 Maven 清理、DNS 刷新等工具。* |

---


## 🔍 工具详解：port (端口溯源)

当你的 8080 端口被占用时，它不只是告诉你 PID，还会把“凶手”的底细查得清清楚楚。

### **✨ 功能特性**
- **智能过滤**：使用idea启动的java项目会自动隐藏臃肿的 Classpath 路径，只看重点。
- **分行展示**：项目地址、启动类、JVM 参数、物理内存独立输出。
- **一键清理**：支持强制结束进程树，彻底释放端口。
- **免右键运行**：内置 UAC 提权逻辑，直接双击即可获得管理员权限。

### **📸 运行预览**

```text
============================================================
          Windows Port Process Analyzer (Smart Kill)
============================================================

Enter Port Number: 8080

Analyzing Port 8080...
------------------------------------------------------------
[FOUND] State: LISTENING | PID: 29996 | Name: java
Memory : 199.05 MB
------------------------------------------------------------
Project Path: D:\code\java\my-project\target\classes
Main Class  : com.example.Application
JVM Args    : -Xms512m -Xmx1024m -Dfile.encoding=UTF-8 [CP]
------------------------------------------------------------

[1] Kill Process (by PID) [2] Search Again [3] Exit
Select Option (1/2/3): 1
Enter PID to Kill: 29996
成功: 已终止 PID 26156 (属于 PID 29996 子进程)的进程。
成功: 已终止 PID 29996 (属于 PID 3944 子进程)的进程。
Process 29996 has been terminated.

```