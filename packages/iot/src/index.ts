/**
 * @axioledger/iot
 *
 * MQTT/WebSocket lightweight data protocol, telemetry decoder.
 * Depends on: @axioledger/network, @axioledger/validation
 */
import mqtt, { type MqttClient, type IClientOptions } from 'mqtt';
import type { ZodSchema } from '@axioledger/validation';

export interface TelemetryStreamOptions<T> {
  brokerUrl: string;
  topic: string;
  schema: ZodSchema<T>;
  mqttOptions?: IClientOptions;
}

export function createTelemetryStream<T>(
  options: TelemetryStreamOptions<T>,
  onData: (payload: T) => void,
  onError?: (err: Error) => void,
): MqttClient {
  const client = mqtt.connect(options.brokerUrl, options.mqttOptions);
  client.subscribe(options.topic);
  client.on('message', (_topic, raw) => {
    try {
      const parsed = JSON.parse(raw.toString()) as unknown;
      const data = options.schema.parse(parsed);
      onData(data);
    } catch (err) {
      onError?.(err instanceof Error ? err : new Error(String(err)));
    }
  });
  return client;
}

export { mqtt };
export type { MqttClient };
