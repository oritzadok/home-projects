# Field Test Analytics

## Scenario
A data collection team regularly runs mobile data collection sessions out in the field. Every so
often, they upload a raw batch file (CSV format) along with some basic metadata representing a
session.
We need a way to move away from looking at raw files and transition to a system where this data
is robustly stored, parsed, and made visible to our team for quick analysis and operational
insights.

## Task
You are provided with a sample raw CSV data file (`field_session_042.csv`) representing a
recent test run.
Design and build a local full-stack application that:
1. Ingests & Processes the Data: Reads the raw file, addresses any real-world data quality
issues present in it, and saves it into a database of your choice.
2. Visualizes & Analyzes: Provides a data visualization dashboard with key statistics or
insights about the session(s).

The solution should be easy to spin up and review. You should provide a
single-command deployment mechanism, ideally using Docker.

## Setup
### Deployment Instructions
1. Ensure Docker and Docker Compose are installed.
2. Run `docker-compose up --build -d` in the root directory.
3. Access the dashboard at `http://localhost:3000`.
4. Access the API documentation at `http://localhost:8000/docs`.
5. Teardown:
   - run `docker-compose down`
   - Delete the postgres data Docker volume

### Future improvements
* Option to upload session metadata, and display it in the dashboard
* Choose a session from history uploads to display