// API Client for Market Prediction Dashboard
// Connects to real API endpoints instead of hardcoded data

const API_BASE_URL = 'http://localhost:5000/api';

class MarketPredictionAPI {
    constructor() {
        this.baseUrl = API_BASE_URL;
    }

    // Get D1 Predictions
    async getPredictions(indexName = null) {
        try {
            const url = indexName 
                ? `${this.baseUrl}/predictions/${indexName}`
                : `${this.baseUrl}/predictions`;
            const response = await fetch(url);
            if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
            return await response.json();
        } catch (error) {
            console.error('Error fetching predictions:', error);
            return null;
        }
    }

    // Get discovered patterns
    async getPatterns(targetType = null, indexName = null, limit = 100) {
        try {
            const params = new URLSearchParams();
            if (targetType) params.append('targetType', targetType);
            if (indexName) params.append('indexName', indexName);
            if (limit) params.append('limit', limit);
            
            const url = `${this.baseUrl}/patterns?${params}`;
            const response = await fetch(url);
            if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
            return await response.json();
        } catch (error) {
            console.error('Error fetching patterns:', error);
            return [];
        }
    }

    // Get live market data
    async getLiveMarket(indexName = null) {
        try {
            const url = indexName
                ? `${this.baseUrl}/livemarket/${indexName}`
                : `${this.baseUrl}/livemarket`;
            const response = await fetch(url);
            if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
            return await response.json();
        } catch (error) {
            console.error('Error fetching live market data:', error);
            return null;
        }
    }

    // Get strategy labels
    async getStrategyLabels(indexName, date = null) {
        try {
            const params = new URLSearchParams();
            params.append('indexName', indexName);
            if (date) params.append('date', date);
            
            const url = `${this.baseUrl}/strategylabels?${params}`;
            const response = await fetch(url);
            if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
            return await response.json();
        } catch (error) {
            console.error('Error fetching strategy labels:', error);
            return [];
        }
    }

    // Get process breakdown (C-, P-, C+, P+)
    async getProcessBreakdown(indexName, date = null) {
        try {
            const params = new URLSearchParams();
            params.append('indexName', indexName);
            if (date) params.append('date', date);
            
            const url = `${this.baseUrl}/processbreakdown?${params}`;
            const response = await fetch(url);
            if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
            return await response.json();
        } catch (error) {
            console.error('Error fetching process breakdown:', error);
            return null;
        }
    }

    // Get pattern statistics
    async getPatternStatistics() {
        try {
            const url = `${this.baseUrl}/patterns/statistics`;
            const response = await fetch(url);
            if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
            return await response.json();
        } catch (error) {
            console.error('Error fetching pattern statistics:', error);
            return null;
        }
    }

    // Health check
    async checkHealth() {
        try {
            const url = `${this.baseUrl}/health`;
            const response = await fetch(url);
            if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
            return await response.json();
        } catch (error) {
            console.error('Error checking health:', error);
            return { status: 'Unhealthy', error: error.message };
        }
    }
}

// Export for use in HTML
if (typeof module !== 'undefined' && module.exports) {
    module.exports = MarketPredictionAPI;
}










