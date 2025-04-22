package com.example.birdshop.repository;

import com.example.birdshop.model.Bird;
import org.springframework.data.jpa.repository.JpaRepository;

public interface BirdRepository extends JpaRepository<Bird, Long> {
}
