import express from "express";

const app = express();
const PORT = 3102;

app.use(express.json());

app.get("/health", (_req, res) => {
    res.status(200).json({
        status: "healthy",
        service: "storage-service",
        timestamp: new Date().toISOString()
    });
});

app.listen(PORT, () => {
    console.log(`Storage Service running on port ${PORT}`);
});