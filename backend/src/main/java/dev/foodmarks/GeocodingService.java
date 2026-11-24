package dev.foodmarks;

import com.fasterxml.jackson.databind.JsonNode;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;
import org.springframework.web.server.ResponseStatusException;
import java.time.*;
import java.util.*;

@Service
public class GeocodingService {
    public record Candidate(String placeId, String label, double latitude, double longitude) {}
    private final String key;
    private final RestClient client = RestClient.builder().baseUrl("https://maps.googleapis.com")
        .requestFactory(new org.springframework.http.client.SimpleClientHttpRequestFactory() {{
            setConnectTimeout(5000); setReadTimeout(8000);
        }}).build();
    private static final List<Candidate> DEMO = List.of(
        new Candidate("demo-seoul-cityhall", "서울특별시 중구 세종대로 110 (데모 위치)", 37.5663, 126.9779),
        new Candidate("demo-seoul-station", "서울특별시 용산구 한강대로 405 (데모 위치)", 37.5547, 126.9706),
        new Candidate("demo-busan-cityhall", "부산광역시 연제구 중앙대로 1001 (데모 위치)", 35.1796, 129.0756));

    public GeocodingService(@Value("${app.google-key}") String key) { this.key = key; }
    public boolean isDemo() { return key.isBlank(); }
    public List<Candidate> search(String address) {
        if (isDemo()) return DEMO.stream().filter(c -> c.label().contains(address.strip()) ||
            (address.contains("서울") && c.placeId().startsWith("demo-seoul")) ||
            (address.contains("부산") && c.placeId().contains("busan"))).toList();
        return query("address", address);
    }
    public Candidate resolve(String placeId) {
        if (isDemo()) return DEMO.stream().filter(c -> c.placeId().equals(placeId)).findFirst()
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.BAD_REQUEST, "데모 주소 후보를 다시 선택해주세요."));
        return query("place_id", placeId).stream().findFirst()
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.BAD_REQUEST, "선택한 장소를 찾지 못했습니다. 주소를 다시 검색해주세요."));
    }
    private List<Candidate> query(String parameter, String value) {
        try {
            JsonNode root = client.get().uri(b -> b.path("/maps/api/geocode/json")
                .queryParam(parameter, value).queryParam("language", "ko").queryParam("key", key).build())
                .retrieve().body(JsonNode.class);
            String status = root.path("status").asText();
            if (status.equals("ZERO_RESULTS")) return List.of();
            if (!status.equals("OK")) throw new IllegalStateException("geocoding unavailable");
            List<Candidate> candidates = new ArrayList<>();
            for (JsonNode r : root.path("results")) {
                JsonNode p = r.path("geometry").path("location");
                candidates.add(new Candidate(r.path("place_id").asText(), r.path("formatted_address").asText(),
                    p.path("lat").asDouble(), p.path("lng").asDouble()));
            }
            return candidates;
        } catch (Exception e) {
            // Do not include the upstream URL (it contains the key) in API errors/logs.
            throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, "주소 검색 서비스를 사용할 수 없습니다. 서버의 API 키·할당량·네트워크를 확인해주세요.");
        }
    }
}
