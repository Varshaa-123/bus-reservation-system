import { useState } from 'react';
import { api } from './api';
import DataTable from './components/DataTable.jsx';
import ReserveSeatForm from './components/ReserveSeatForm.jsx';
import FareCalculator from './components/FareCalculator.jsx';
import AddPassengerForm from './components/AddPassengerForm.jsx';

const money = (value) => `₹${Number(value).toFixed(2)}`;
const dateTime = (value) => new Date(value).toLocaleString('en-IN');
const timeOnly = (value) => String(value).slice(0, 5);

// Each table view: which API to call and which columns to show.
const TABLE_VIEWS = {
  reservations: {
    title: 'Reservations (JOIN stored procedure)',
    load: api.getReservations,
    columns: [
      { key: 'reservationId', label: 'Reservation ID' },
      { key: 'passengerName', label: 'Passenger' },
      { key: 'phone', label: 'Phone' },
      { key: 'source', label: 'Source' },
      { key: 'destination', label: 'Destination' },
      { key: 'busName', label: 'Bus', render: (v, row) => `${row.busName} (${row.busNumber})` },
      { key: 'seatNumber', label: 'Seat' },
      { key: 'reservationDate', label: 'Date', render: (v) => dateTime(v) },
      { key: 'fare', label: 'Fare', render: (v) => money(v) },
      {
        key: 'status',
        label: 'Status',
        render: (v) => <span className={`badge ${v === 'CONFIRMED' ? 'ok' : 'cancelled'}`}>{v}</span>,
      },
    ],
  },
  aboveAverage: {
    title: 'Routes With Bookings Above Average (SUBQUERY stored procedure)',
    load: api.getRoutesAboveAverage,
    columns: [
      { key: 'routeId', label: 'Route' },
      { key: 'source', label: 'Source' },
      { key: 'destination', label: 'Destination' },
      { key: 'busName', label: 'Bus' },
      { key: 'bookingCount', label: 'Booking Count' },
      { key: 'averageBookingCount', label: 'Average Booking Count' },
    ],
  },
  buses: {
    title: 'Buses',
    load: api.getBuses,
    columns: [
      { key: 'busId', label: 'Bus ID' },
      { key: 'busNumber', label: 'Bus Number' },
      { key: 'busName', label: 'Bus Name' },
      { key: 'totalSeats', label: 'Total Seats' },
      { key: 'availableSeats', label: 'Available Seats' },
    ],
  },
  routes: {
    title: 'Routes',
    load: api.getRoutes,
    columns: [
      { key: 'routeId', label: 'Route ID' },
      { key: 'source', label: 'Source' },
      { key: 'destination', label: 'Destination' },
      { key: 'departureTime', label: 'Departure', render: (v) => timeOnly(v) },
      { key: 'arrivalTime', label: 'Arrival', render: (v) => timeOnly(v) },
      { key: 'fare', label: 'Base Fare', render: (v) => money(v) },
      { key: 'busId', label: 'Bus ID' },
    ],
  },
  passengers: {
    title: 'Passengers',
    load: api.getPassengers,
    columns: [
      { key: 'passengerId', label: 'Passenger ID' },
      { key: 'name', label: 'Name' },
      { key: 'email', label: 'Email' },
      { key: 'phone', label: 'Phone' },
    ],
  },
};

const CARDS = [
  { id: 'reservations', icon: '🎫', title: 'View Reservations', text: 'Passenger, route and bus details using a JOIN.', button: 'View Reservations' },
  { id: 'aboveAverage', icon: '📈', title: 'Routes Above Average', text: 'Routes with more bookings than average (SUBQUERY).', button: 'Find Routes Above Average' },
  { id: 'reserve', icon: '💺', title: 'Reserve Seat', text: 'Book a seat using the reserve_seat procedure.', button: 'Open Reserve Form' },
  { id: 'fare', icon: '💰', title: 'Calculate Fare', text: 'Fare calculated by a MySQL function.', button: 'Open Fare Calculator' },
  { id: 'buses', icon: '🚌', title: 'View Buses', text: 'All buses and their available seats.', button: 'View Buses' },
  { id: 'routes', icon: '🗺️', title: 'View Routes', text: 'All routes with timings and fares.', button: 'View Routes' },
  { id: 'passengers', icon: '🧑‍🤝‍🧑', title: 'View Passengers', text: 'All registered passengers.', button: 'View Passengers' },
];

export default function App() {
  const [active, setActive] = useState(null);
  const [rows, setRows] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  async function openCard(id) {
    setActive(id);
    setError('');
    setRows([]);

    const view = TABLE_VIEWS[id];
    if (!view) return; // forms (reserve / fare) load nothing

    setLoading(true);
    try {
      setRows(await view.load());
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }

  async function reloadActive() {
    const view = TABLE_VIEWS[active];
    if (!view) return;
    try {
      setRows(await view.load());
    } catch (err) {
      setError(err.message);
    }
  }

  const view = TABLE_VIEWS[active];

  return (
    <div className="app">
      <header className="header">
        <h1>🚍 Bus Reservation System</h1>
        <p>React → Spring Boot REST API → MySQL procedures, function and triggers</p>
      </header>

      <section className="cards">
        {CARDS.map((card) => (
          <div key={card.id} className={`card ${active === card.id ? 'selected' : ''}`}>
            <div className="card-icon">{card.icon}</div>
            <h3>{card.title}</h3>
            <p>{card.text}</p>
            <button onClick={() => openCard(card.id)}>{card.button}</button>
          </div>
        ))}
      </section>

      <main className="panel">
        {!active && <p className="hint">Click any button above to call the backend API.</p>}

        {active === 'reserve' && (
          <>
            <h2>Reserve Seat</h2>
            <ReserveSeatForm />
          </>
        )}

        {active === 'fare' && (
          <>
            <h2>Calculate Fare</h2>
            <FareCalculator />
          </>
        )}

        {view && (
          <>
            <h2>{view.title}</h2>
            {active === 'passengers' && <AddPassengerForm onCreated={reloadActive} />}
            {loading && <p className="hint">Loading…</p>}
            {error && <p className="message error">{error}</p>}
            {!loading && !error && <DataTable columns={view.columns} rows={rows} />}
          </>
        )}
      </main>
    </div>
  );
}
