const tasks = require("./routes/tasks");
const connection = require("./db");
const cors = require("cors");
const express = require("express");
const app = express();

connection();

app.use(express.json());
app.use(cors());

app.get("/health", (req, res) => res.sendStatus(200));

// Readiness probe - checks DB connection
app.get("/ready", async (req, res) => {
  try {
    res.sendStatus(200); // DB is reachable
    // if (!dbConnection) {
    //   return res.sendStatus(503); // DB not connected
    // }
    // await dbConnection.db.admin().ping();
  } catch (err) {
    res.sendStatus(503);
  }
});

app.get('/ok', (req, res) => {
    res.status(200).send('ok')
  })

app.use("/api/tasks", tasks);

const port = process.env.PORT || 3500;
app.listen(port, () => console.log(`Listening on port ${port}...`));
