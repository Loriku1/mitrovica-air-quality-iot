import express from "express";

const app = express();
const PORT = 3101;

app.use(express.json());

app.get("/health", (_req, res) => {
    res.status(200).json({
        status: "healthy",
        service: "ingestion-service",
        timestamp: new Date().toISOString()
    });
});

app.listen(PORT, () => {
    console.log(`Ingestion Service running on port ${PORT}`);
});