import { Room, RoomSearchCriteria } from '../types';
declare class FirestoreService {
    private db;
    private initialized;
    constructor();
    private initialize;
    /**
     * Aktif odaları getir - ÇEŞİTLİLİK İÇİN SHUFFLE
     */
    getActiveRooms(criteria?: RoomSearchCriteria): Promise<Room[]>;
    /**
     * Fisher-Yates shuffle algoritması
     */
    private shuffleArray;
    /**
     * Belirli odaları hariç tut ve getir
     */
    getActiveRoomsExcluding(excludeRoomIds: string[], criteria?: RoomSearchCriteria): Promise<Room[]>;
    /**
     * Tek oda getir
     */
    getRoom(roomId: string): Promise<Room | null>;
    /**
     * Kategori bazlı oda sayısı
     */
    getRoomCountByCategory(): Promise<Record<string, number>>;
    /**
     * Popüler kategoriler
     */
    getPopularCategories(limit?: number): Promise<string[]>;
    /**
     * Bağlantı durumu
     */
    isConnected(): boolean;
    /**
     * Test bağlantısı
     */
    testConnection(): Promise<{
        success: boolean;
        message: string;
        roomCount?: number;
    }>;
}
export declare const firestoreService: FirestoreService;
export default FirestoreService;
