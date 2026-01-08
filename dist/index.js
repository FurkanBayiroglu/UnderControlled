"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.handler = void 0;
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const helmet_1 = __importDefault(require("helmet"));
const serverless_http_1 = __importDefault(require("serverless-http"));
const dotenv_1 = __importDefault(require("dotenv"));
// Routes
const chat_1 = __importDefault(require("./routes/chat"));
const recommendation_1 = __importDefault(require("./routes/recommendation"));
const health_1 = __importDefault(require("./routes/health"));
// Load environment variables
dotenv_1.default.config();
const app = (0, express_1.default)();
// Middleware
app.use((0, helmet_1.default)({
    crossOriginResourcePolicy: { policy: 'cross-origin' }
}));
app.use((0, cors_1.default)({
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization']
}));
app.use(express_1.default.json({ limit: '10mb' }));
app.use(express_1.default.urlencoded({ extended: true }));
// Request logging
app.use((req, _res, next) => {
    console.log(`[${new Date().toISOString()}] ${req.method} ${req.path}`);
    next();
});
// Routes
app.use('/api/chat', chat_1.default);
app.use('/api/recommend', recommendation_1.default);
app.use('/api/health', health_1.default);
// Root endpoint
app.get('/', (_req, res) => {
    res.json({
        name: 'UnderControl AI Backend',
        version: '2.0.0',
        status: 'running',
        endpoints: {
            health: '/api/health',
            chat: '/api/chat',
            recommend: '/api/recommend'
        }
    });
});
// 404 handler
app.use((_req, res) => {
    res.status(404).json({ error: 'Endpoint bulunamadı' });
});
// Error handler
app.use((err, _req, res, _next) => {
    console.error('Server error:', err);
    res.status(500).json({
        error: 'Sunucu hatası',
        message: process.env.NODE_ENV === 'development' ? err.message : undefined
    });
});
// Local development
if (process.env.NODE_ENV !== 'production') {
    const PORT = process.env.PORT || 3000;
    app.listen(PORT, () => {
        console.log(`🚀 Server running on http://localhost:${PORT}`);
        console.log(`📊 Health check: http://localhost:${PORT}/api/health`);
    });
}
// Lambda handler
exports.handler = (0, serverless_http_1.default)(app);
exports.default = app;
//# sourceMappingURL=index.js.map