declare module 'redis' {
	export interface RedisClient extends NodeJS.EventEmitter {
		smembersAsync(...args: any[]): Promise<Array<string>>;
		zrangebyscoreAsync(...args: any[]): Promise<Array<string>>;
	}
}