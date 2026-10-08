# 🚍 Bus Reservation System

A full-stack DBMS project built using **React + Spring Boot + MySQL 8**.

All core database logic — including **JOIN, SUBQUERY, seat reservation, fare calculation, and seat-count updates** — is implemented inside MySQL using stored procedures, a function, and triggers. Spring Boot calls these database objects and exposes REST APIs.

---

## 1. Problem Statement

Manage buses, routes, passengers, and reservations through a full-stack web application.

---

## 2. Features

* View all reservations with passenger, route, and bus details using a **JOIN stored procedure**
* Find routes whose bookings are above the average using a **SUBQUERY stored procedure**
* Reserve a seat using a stored procedure with validation and transaction handling
* Calculate fare using a MySQL function
* Automatically update available seats using triggers
* Cancel a reservation using a stored procedure and trigger
* Add and list passengers
* List buses and routes
* JSON error responses with proper HTTP status codes

---

## 3. Technologies Used

| Layer    | Technology                                                                 |
| -------- | -------------------------------------------------------------------------- |
| Database | MySQL 8.x                                                                  |
| Backend  | Java 21, Spring Boot 3.3, Spring Web, Spring Data JPA, JdbcTemplate, Maven |
| Frontend | React 18, Vite 5, JavaScript, CSS                                          |

---

## 4. Database Schema

```text
buses(
    bus_id PK,
    bus_number UNIQUE,
    bus_name,
    total_seats,
    available_seats
)

routes(
    route_id PK,
    source,
    destination,
    departure_time,
    arrival_time,
    fare,
    bus_id FK UNIQUE
)

passengers(
    passenger_id PK,
    name,
    email UNIQUE,
    phone UNIQUE
)

reservations(
    reservation_id PK,
    passenger_id FK,
    route_id FK,
    seat_number,
    reservation_date,
    status,
    fare,
    confirmed_seat [generated]
)
```

---

## 5. ER Diagram Description

```text
BUSES 1 ───────── 1 ROUTES 1 ───────── * RESERVATIONS * ───────── 1 PASSENGERS

(bus_id)           (bus_id FK)          (route_id FK)              (passenger_id FK)
```

* One **bus** operates one **route** (`routes.bus_id` is UNIQUE). This keeps `buses.available_seats` accurate.
* One **route** has many **reservations**.
* One **passenger** can have many **reservations**.
* A **reservation** connects exactly one passenger to exactly one route and therefore one bus.

---

## 6. Table Descriptions

| Table          | Purpose                                     | Key Constraints                                                                                                                                      |
| -------------- | ------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| `buses`        | Bus details and seat counts                 | PK `bus_id`; UNIQUE `bus_number`; CHECK `0 <= available_seats <= total_seats`                                                                        |
| `routes`       | Source, destination, timings, and base fare | PK `route_id`; FK `bus_id` → `buses`; CHECK `source <> destination`, `fare > 0`                                                                      |
| `passengers`   | Passenger contact details                   | PK `passenger_id`; UNIQUE `email`, `phone`                                                                                                           |
| `reservations` | One row per booked seat                     | PK `reservation_id`; FKs to passengers and routes; UNIQUE `(route_id, confirmed_seat)` prevents double booking; `status` = `CONFIRMED` / `CANCELLED` |

`confirmed_seat` is a generated column equal to `seat_number` while the reservation is `CONFIRMED` and `NULL` when `CANCELLED`.

Because MySQL ignores `NULL` values in UNIQUE keys, a cancelled seat can be booked again, but a seat can never be booked twice at the same time.

---

## 7. Stored Procedures

| Procedure                                           | Purpose                                                                               |
| --------------------------------------------------- | ------------------------------------------------------------------------------------- |
| `get_reservation_details()`                         | JOIN of reservations, passengers, routes, and buses                                   |
| `get_routes_above_average_bookings()`               | Routes with bookings above the average using a SUBQUERY                               |
| `reserve_seat(passenger_id, route_id, seat_number)` | Validates and books a seat; returns `status`, `message`, `reservation_id`, and `fare` |
| `cancel_reservation(reservation_id)`                | Cancels a reservation                                                                 |

`reserve_seat` performs the following operations:

1. Checks whether the passenger exists.
2. Checks whether the route exists.
3. Validates the seat number.
4. Checks whether the seat is already booked.
5. Checks whether seats are available.
6. Calculates the fare using `calculate_fare()`.
7. Inserts the reservation.
8. The trigger updates the available seat count.
9. The transaction is committed.

The procedure locks the bus row using `FOR UPDATE` inside a transaction so that two users cannot book the same available seat simultaneously.

---

## 8. Function

`calculate_fare(route_id)` returns:

```text
Base Fare + 5% GST
```

The result is rounded to 2 decimal places.

If the route does not exist, the function returns `NULL`.

### Example

```text
Base fare = ₹550.00

GST = ₹27.50

Final fare = ₹577.50
```

---

## 9. Triggers

| Trigger                         | Event                         | Action                                                       |
| ------------------------------- | ----------------------------- | ------------------------------------------------------------ |
| `trg_reservation_before_insert` | BEFORE INSERT on reservations | Rejects a CONFIRMED booking if the bus has no seats left     |
| `trg_reservation_after_insert`  | AFTER INSERT on reservations  | Decreases `available_seats` by 1                             |
| `trg_reservation_after_update`  | AFTER UPDATE on reservations  | When CONFIRMED → CANCELLED, increases `available_seats` by 1 |

The Java backend never directly changes `available_seats`.

The seat count is maintained by the MySQL triggers.

---

## 10. JOIN Explanation

`get_reservation_details()` joins four tables:

```sql
FROM reservations res

JOIN passengers p
    ON p.passenger_id = res.passenger_id

JOIN routes r
    ON r.route_id = res.route_id

JOIN buses b
    ON b.bus_id = r.bus_id
```

Each reservation row is combined with:

* Passenger information
* Route information
* Bus information

This demonstrates the use of multiple-table JOIN operations.

---

## 11. SUBQUERY Explanation

`get_routes_above_average_bookings()` counts confirmed bookings per route and keeps only routes whose booking count is greater than the average.

The average is calculated using a subquery in the `HAVING` clause.

Conceptually:

```sql
HAVING COUNT(res.reservation_id) >
       (
           SELECT AVG(t2.cnt)
           FROM (
               SELECT COUNT(...) AS cnt
               FROM routes ...
               GROUP BY route_id
           ) AS t2
       )
```

Nothing is hard-coded.

With the sample data, the average booking count is **2.25**, and the result contains routes **1, 2, and 6**.

---

## 12. REST API Documentation

| Method | URL                             | Description                   | Database Object Used                  |
| ------ | ------------------------------- | ----------------------------- | ------------------------------------- |
| GET    | `/api/reservations`             | Reservation details           | `get_reservation_details()`           |
| GET    | `/api/routes/above-average`     | Routes above average bookings | `get_routes_above_average_bookings()` |
| POST   | `/api/reservations`             | Reserve a seat                | `reserve_seat()`                      |
| POST   | `/api/reservations/{id}/cancel` | Cancel a reservation          | `cancel_reservation()`                |
| GET    | `/api/routes/{routeId}/fare`    | Calculate fare                | `calculate_fare()`                    |
| GET    | `/api/buses`                    | List buses                    | `buses` table                         |
| GET    | `/api/routes`                   | List routes                   | `routes` table                        |
| GET    | `/api/passengers`               | List passengers               | `passengers` table                    |
| POST   | `/api/passengers`               | Create passenger              | `passengers` table                    |

### HTTP Status Codes

| Situation                                                   | HTTP Status |
| ----------------------------------------------------------- | ----------: |
| Seat reserved                                               |         201 |
| Invalid input / seat out of range                           |         400 |
| Passenger, route, or reservation not found                  |         404 |
| Seat already reserved / no seats / duplicate email or phone |         409 |
| Database unavailable                                        |         503 |
| Unexpected error                                            |         500 |

---

## 13. Frontend Features

The dashboard contains 7 main buttons.

Every action communicates with the REST API.

### 1. View Reservations

```text
GET /api/reservations
```

Displays reservation information including passenger, route, and bus details.

### 2. Find Routes Above Average

```text
GET /api/routes/above-average
```

Displays routes whose booking count is above the average.

### 3. Reserve Seat

```text
POST /api/reservations
```

Provides a form for passenger ID, route ID, and seat number.

### 4. Calculate Fare

```text
GET /api/routes/{id}/fare
```

Calculates the final fare for a route.

### 5. View Buses

```text
GET /api/buses
```

Displays the available buses and their seat counts.

### 6. View Routes

```text
GET /api/routes
```

Displays route information.

### 7. View Passengers

```text
GET /api/passengers
```

Displays passengers.

The frontend also provides an **Add Passenger** form:

```text
POST /api/passengers
```

---

## 14. Project Folder Structure

```text
bus-reservation-system/
│
├── backend/
│   ├── src/
│   │   └── main/
│   │       ├── java/
│   │       │   └── com/example/busreservation/
│   │       │       ├── BusReservationApplication.java
│   │       │       ├── config/
│   │       │       │   └── CorsConfig.java
│   │       │       ├── controller/
│   │       │       │   ├── BusController.java
│   │       │       │   ├── RouteController.java
│   │       │       │   ├── PassengerController.java
│   │       │       │   └── ReservationController.java
│   │       │       ├── dto/
│   │       │       │   ├── request/
│   │       │       │   ├── response/
│   │       │       │   └── error/
│   │       │       ├── entity/
│   │       │       │   ├── Bus.java
│   │       │       │   ├── Route.java
│   │       │       │   └── Passenger.java
│   │       │       ├── exception/
│   │       │       ├── repository/
│   │       │       └── service/
│   │       │
│   │       └── resources/
│   │           └── application.properties
│   │
│   └── pom.xml
│
├── frontend/
│   ├── src/
│   │   ├── main.jsx
│   │   ├── App.jsx
│   │   ├── api.js
│   │   ├── styles.css
│   │   └── components/
│   ├── index.html
│   ├── package.json
│   └── vite.config.js
│
├── database/
│   └── init.sql
│
├── .env.example
├── .gitignore
└── README.md
```

---

## 15. Run Locally

### Prerequisites

Install:

* Java 21
* Maven 3.9+
* Node.js 20+
* MySQL 8.x

---

### Step 1 — Start MySQL

On Windows, start the MySQL service.

On Linux:

```bash
sudo systemctl start mysql
```

---

### Step 2 — Create the Database

The `database/init.sql` file creates:

* Database
* Tables
* Sample data
* Stored procedures
* Function
* Triggers

Run:

```bash
mysql -u root -p < database/init.sql
```

---

### Step 3 — Verify the Database

Run:

```bash
mysql -u root -p -e "USE bus_reservation; SELECT bus_name, available_seats FROM buses;"
```

You should see the buses and their available seat counts.

---

### Step 4 — Configure the Backend

The backend uses environment variables for database configuration.

The default configuration is:

```text
Database: bus_reservation
Host: localhost
Port: 3306
Username: root
Password: root
```

If your MySQL root password is different, set the password using an environment variable.

### Windows PowerShell

```powershell
$env:DB_PASSWORD="your_password"
```

### Windows CMD

```cmd
set DB_PASSWORD=your_password
```

### Linux / macOS

```bash
export DB_PASSWORD=your_password
```

You can also configure the values in:

```text
backend/src/main/resources/application.properties
```

**Do not commit your real database password to GitHub.**

---

### Step 5 — Start Spring Boot

Open a terminal:

```bash
cd backend
mvn spring-boot:run
```

The backend runs on:

```text
http://localhost:8080
```

Test the backend:

```text
http://localhost:8080/api/buses
```

---

### Step 6 — Start React

Open another terminal:

```bash
cd frontend
npm install
npm run dev
```

The frontend runs on:

```text
http://localhost:5173
```

---

### Step 7 — Open the Application

Open:

```text
http://localhost:5173
```

---

## 16. API Testing

### Browser — GET Requests

Test the following URLs:

```text
http://localhost:8080/api/reservations
```

```text
http://localhost:8080/api/routes/above-average
```

```text
http://localhost:8080/api/routes/1/fare
```

```text
http://localhost:8080/api/buses
```

```text
http://localhost:8080/api/routes
```

```text
http://localhost:8080/api/passengers
```

---

### Postman — Reserve a Seat

**POST**

```text
http://localhost:8080/api/reservations
```

Body → raw → JSON:

```json
{
    "passengerId": 11,
    "routeId": 1,
    "seatNumber": 20
}
```

---

### Postman — Create Passenger

**POST**

```text
http://localhost:8080/api/passengers
```

Body → raw → JSON:

```json
{
    "name": "Test Passenger",
    "email": "test.passenger@example.com",
    "phone": "9000000001"
}
```

---

### Postman — Cancel Reservation

**POST**

```text
http://localhost:8080/api/reservations/1/cancel
```

No request body is required.

---

## 17. Sample Requests / Responses

### Calculate Fare

```text
GET /api/routes/1/fare
```

Response:

```json
{
    "routeId": 1,
    "fare": 577.50
}
```

---

### Reserve a Seat

```text
POST /api/reservations
```

Example:

```json
{
    "passengerId": 11,
    "routeId": 1,
    "seatNumber": 20
}
```

Response:

```json
{
    "status": "SUCCESS",
    "message": "Seat 20 reserved successfully.",
    "reservationId": 20,
    "fare": 577.50
}
```

---

### Same Seat Again

Response:

```text
HTTP 409 Conflict
```

```json
{
    "timestamp": "2026-10-01T10:15:30",
    "status": 409,
    "error": "Conflict",
    "message": "Seat 20 is already reserved for this route."
}
```

---

### Invalid Seat

For example, route 1 has 40 seats.

```text
HTTP 400 Bad Request
```

```json
{
    "timestamp": "2026-10-01T10:16:02",
    "status": 400,
    "error": "Bad Request",
    "message": "Invalid seat number. Seat must be between 1 and 40."
}
```

---

### Unknown Passenger

```text
HTTP 404 Not Found
```

```json
{
    "timestamp": "2026-10-01T10:16:40",
    "status": 404,
    "error": "Not Found",
    "message": "Passenger with ID 99 does not exist."
}
```

---

### Routes Above Average

```text
GET /api/routes/above-average
```

Example response:

```json
[
    {
        "routeId": 1,
        "source": "Chennai",
        "destination": "Madurai",
        "busName": "Parveen Travels",
        "bookingCount": 4,
        "averageBookingCount": 2.25
    },
    {
        "routeId": 2,
        "source": "Chennai",
        "destination": "Coimbatore",
        "busName": "SRS Express",
        "bookingCount": 4,
        "averageBookingCount": 2.25
    },
    {
        "routeId": 6,
        "source": "Chennai",
        "destination": "Pondicherry",
        "busName": "SETC Ultra Deluxe",
        "bookingCount": 3,
        "averageBookingCount": 2.25
    }
]
```

---

## 18. Demo Idea for Faculty

A simple demonstration of the database logic:

### Step 1

Click **View Buses**.

Observe that route 1's bus, **Parveen Travels**, has:

```text
36 available seats
```

### Step 2

Reserve seat 20 on route 1 for passenger 11.

### Step 3

Click **View Buses** again.

The available seats should now show:

```text
35
```

The seat count was updated by the **MySQL trigger**, not directly by Java.

### Step 4

Cancel reservation 20 using Postman.

### Step 5

Check the buses again.

The available seat count should return to:

```text
36
```

This demonstrates the interaction between:

```text
REST API
   ↓
Spring Boot
   ↓
Stored Procedure
   ↓
MySQL
   ↓
Trigger
   ↓
Updated Seat Count
```

---

## 19. GitHub Commands

Create or obtain an **empty GitHub repository** first.

The repository should ideally contain no initial README or `.gitignore` when connecting an existing local project.

From the project root:

```bash
git init
```

Check the project:

```bash
git status
```

Add the files:

```bash
git add .
```

Create the first commit:

```bash
git commit -m "Initial commit - Bus Reservation System"
```

Set the main branch:

```bash
git branch -M main
```

Connect the GitHub repository:

```bash
git remote add origin <YOUR_GITHUB_REPOSITORY_URL>
```

Push the project:

```bash
git push -u origin main
```

Replace:

```text
<YOUR_GITHUB_REPOSITORY_URL>
```

with the actual GitHub repository URL.

Example:

```text
https://github.com/your-username/bus-reservation-system.git
```

### Important

Do not commit:

```text
.env
backend/target/
frontend/node_modules/
frontend/dist/
```

These files and folders are excluded through `.gitignore`.

---

## Project Status

The current version of this project is the **normal local development version**.

The project contains:

```text
React Frontend
       ↓
Spring Boot REST API
       ↓
MySQL Database
       ↓
Stored Procedures
       ↓
Functions
       ↓
Triggers
```

The source code can be uploaded to GitHub and maintained as the main project repository.
