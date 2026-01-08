import { ChatMessage, ChatResponse, UserPreferences } from '../types';
import { Language } from '../utils/prompts';
declare class GroqService {
    private client;
    private model;
    constructor();
    /**
     * Ana chat fonksiyonu
     */
    chat(messages: ChatMessage[], userPreferences?: UserPreferences, language?: Language): Promise<ChatResponse>;
    /**
     * Mood analizi
     */
    analyzeMood(userMessage: string, language?: Language): Promise<{
        mood: string;
        energy: 'low' | 'medium' | 'high';
        socialLevel: 'solo' | 'small' | 'large';
        suggestedCategories: string[];
    }>;
    /**
     * Oda önerisi açıklaması - HER ODA İÇİN FARKLI
     */
    generateRoomExplanations(rooms: any[], userPreferences: UserPreferences, language?: Language): Promise<Map<string, string>>;
    /**
     * Varsayılan açıklama
     */
    private getDefaultExplanation;
    /**
     * Response analizi
     */
    private analyzeResponse;
}
export declare const groqService: GroqService;
export default GroqService;
