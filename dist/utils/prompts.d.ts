/**
 * UnderControl AI Assistant System Prompts
 * Supports: Turkish (tr) and English (en)
 */
export type Language = 'tr' | 'en';
export declare function getPrompts(language?: Language): {
    assistant: string;
    moodAnalyzer: string;
    roomRecommender: string;
    welcomeMessage: (userName?: string) => string;
    quickReplies: {
        text: string;
        value: string;
    }[];
};
export declare const SYSTEM_PROMPTS: {
    assistant: string;
    moodAnalyzer: string;
    roomRecommender: string;
    welcomeMessage: (userName?: string) => string;
    quickReplies: {
        text: string;
        value: string;
    }[];
};
declare const _default: {
    getPrompts: typeof getPrompts;
    SYSTEM_PROMPTS: {
        assistant: string;
        moodAnalyzer: string;
        roomRecommender: string;
        welcomeMessage: (userName?: string) => string;
        quickReplies: {
            text: string;
            value: string;
        }[];
    };
};
export default _default;
