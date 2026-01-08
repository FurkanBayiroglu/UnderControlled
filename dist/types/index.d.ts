export interface ChatMessage {
    role: 'user' | 'assistant' | 'system';
    content: string;
    timestamp?: string;
}
export interface ChatRequest {
    userId: string;
    sessionId?: string;
    message: string;
    preferences?: UserPreferences;
}
export interface ChatResponse {
    success: boolean;
    message?: string;
    intent?: string;
    suggestedCategories?: string[];
    shouldRecommendRooms?: boolean;
    usage?: TokenUsage;
    error?: string;
}
export interface TokenUsage {
    promptTokens: number;
    completionTokens: number;
    totalTokens: number;
}
export interface UserPreferences {
    mood?: string;
    energy?: 'low' | 'medium' | 'high';
    groupSize?: 'solo' | 'small' | 'medium' | 'large';
    categories?: string[];
    duration?: number;
}
export interface Room {
    id: string;
    name: string;
    description: string;
    category: string;
    createdBy: string;
    createdAt: string;
    eventDate: string;
    eventTime: string;
    durationMinutes: number;
    participants: string[];
    participantCount: number;
    maxParticipants: number;
    isActive: boolean;
    isPrivate: boolean;
}
export interface RoomSearchCriteria {
    categories?: string[];
    excludeUserId?: string;
    limit?: number;
    minParticipants?: number;
    maxParticipants?: number;
}
export interface RecommendationRequest {
    userId: string;
    preferences?: UserPreferences;
    limit?: number;
}
export interface RoomRecommendation extends Room {
    score: number;
    matchReason: string;
    aiExplanation?: string;
}
export interface Session {
    messages: ChatMessage[];
    preferences: UserPreferences;
    createdAt: Date;
    recommendedRoomIds: string[];
}
export declare const CATEGORIES: Record<string, {
    name: string;
    emoji: string;
    keywords: string[];
}>;
export declare const MOOD_CATEGORIES: Record<string, string[]>;
