# Bash DB Engine

A lightweight, command-line database engine implemented entirely in Bash, offering user management, database operations, and basic SQL query handling.

---

## Table of Contents

- [View Web Page Version](https://abdalhameedahmed.github.io/db-engine/)
- [Features](#features)  
- [Getting Started](#getting-started)  
  - [Prerequisites](#prerequisites)  
  - [Installation](#installation)  
- [Usage](#usage)  
  - [User Authentication](#user-authentication)  
  - [Normal User Operations](#normal-user-operations)  
  - [Admin Dashboard](#admin-dashboard)  
- [Supported SQL Queries](#supported-sql-queries)  
- [Data Types & Constraints](#data-types--constraints)  
- [Contributing](#contributing)  
- [License](#license)

---

## View Online
You can view an interactive web page version of this README [here](https://abdalhameedahmed.github.io/db-engine/).

## Features

This Bash DB Engine provides a robust set of features for managing databases directly from your terminal:

### User Authentication

- Secure login and registration for new users.

### Role-Based Access Control

- The first registered user automatically becomes the Admin.
- Subsequent registrations create Normal Users.

### Normal User Capabilities

- Create personal databases.
- List existing databases.
- Remove databases.
- Connect to a specific database to execute queries.

### SQL Query Support

Handles fundamental SQL operations:

- `CREATE`
- `UPDATE`
- `INSERT`
- `DELETE`

### Supported Data Types

- `INT` (Integer)
- `VARCHAR(length)` (Variable Character String with specified length)

### Supported Constraints

- `PRIMARY KEY`
- `FOREIGN KEY`
- `NOT NULL`
- `UNIQUE`

### Admin Dashboard

A powerful interface for administrators:

- Perform all normal user operations.
- Connect to any user's account and manage their databases.

### User Management

- Lock/Unlock user accounts with a custom message displayed upon login attempt.
- List all registered users and view their online/offline status.
- Terminate active user sessions by killing their process.

---

## Getting Started

Follow these instructions to get a copy of the project up and running on your local machine.

### Prerequisites

- A Unix-like operating system (Linux, macOS)
- Bash shell (version 4.0 or higher recommended)

### Installation

1. Clone the repository:

   ```bash
   https://github.com/AbdalhameedAhmed/db-engine.git
   ```

2. Navigate into the project directory:

   ```bash
   cd db-engine
   ```

3. Make the main script executable:

   ```bash
   chmod +x db-engine.sh
   ```

---

## Usage

To start the DB Engine, simply run the main script:

```bash
./db-engine.sh
```

### User Authentication

Upon launching the script, you will be prompted to **create** a new admin,
After registering the admin successfully, you will be prompted to either **login** or **create** a new user.
- **Register:** If this is the first time running the engine, create an account. This account will automatically be assigned Admin privileges. Subsequent registrations will create normal user accounts.
- **Login:** Use your registered credentials to access your account.

---

## Normal User Operations

Once logged in as a normal user, you will be presented with options to:

```bash
create database 
list databases
remove database 
connect to database
```

(Connecting to a database will prompt you for SQL queries.)

---

## Admin Dashboard

When an admin user logs in, they gain access to an extended dashboard with additional powerful commands:

- **Standard Database Operations:** Same as normal users.
- **Connect to User:**

- **Lock User:**

- **Unlock User:**

- **List Users:**

- **Terminate active user Session:**

---

## Supported SQL Queries

When connected to a database, you can execute the following SQL queries:

- **Create Table:**

  ```sql
  CREATE TABLE table_name (column1 datatype [constraint], column2 datatype [constraint], ...);
  ```

- **Insert Into:**

  ```sql
  INSERT INTO table_name (column1, column2) VALUES (value1, value2);
  ```

- **Update:**

  ```sql
  UPDATE table_name SET column1 = new_value WHERE condition;
  ```

- **Delete From:**

  ```sql
  DELETE FROM table_name WHERE condition;
  ```

---

## Data Types & Constraints

### Data Types

- `INT`: For integer values.
- `VARCHAR(length)`: For strings, where `length` specifies the maximum number of characters.

### Constraints

- `PRIMARY KEY`: Uniquely identifies each record in a table.
- `FOREIGN KEY`: Links two tables together.
- `NOT NULL`: Ensures that a column cannot have a NULL value.
- `UNIQUE`: Ensures that all values in a column are different.

---

## Contributing

Contributions are welcome! If you have suggestions for improvements or find any bugs, please open an issue or submit a pull request.

---

## License

This project is open-source and available under the **MIT License**.
