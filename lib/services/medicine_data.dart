class MedicineData {
  static const Map<String, Map<String, dynamic>> database = {
    // 1. Dolo 650
    "8901088012345": {
      "name": "Dolo 650",
      "dosage": "One tablet after lunch when you have fever",
      "uses": "Fever, Body Ache, Mild Pain Relief",
      "sideEffects": "Nausea, Allergic Skin Rash (rare)",
      "warning": "Do not take more than 4 tablets in 24 hours.",
    },

    // 2. Saridon
    "8901234009988": {
      "name": "Saridon",
      "dosage": "One tablet with water for quick headache relief",
      "uses": "Severe Headache, Toothache, Migraine",
      "sideEffects": "Increased Heart Rate, Insomnia, Acidity",
      "warning": "Limit coffee intake as this contains caffeine.",
    },

    // 3. Combiflam
    "8901234005511": {
      "name": "Combiflam",
      "dosage": "One tablet after a meal to avoid stomach pain",
      "uses": "Muscle Pain, Joint Pain, Period Cramps",
      "sideEffects": "Stomach Upset, Heartburn, Dizziness",
      "warning": "Avoid taking on an empty stomach to prevent acidity.",
    },

    // 4. Crocin Advance
    "8901234005522": {
      "name": "Crocin Advance",
      "dosage": "One tablet when needed for fever",
      "uses": "Fever, Mild Aches",
      "sideEffects": "Rarely Causes Sleepiness, Skin Redness",
      "warning": "Wait at least 4 hours before taking another dose.",
    },

    // 5. Digene
    "8901234001122": {
      "name": "Digene",
      "dosage": "Two small spoons of syrup or chew two tablets after meals",
      "uses": "Acidity, Heartburn, Gas, Stomach Bloating",
      "sideEffects": "Constipation, Diarrhea (if taken too much)",
      "warning": "Chew tablets thoroughly before swallowing.",
    },

    // 6. Pantocid 40
    "8901234002233": {
      "name": "Pantocid 40",
      "dosage": "One tablet on an empty stomach, first thing in the morning",
      "uses": "Heartburn, GERD, Stomach Ulcers",
      "sideEffects": "Headache, Diarrhea, Flatulence",
      "warning": "Best taken 30 minutes before your first meal.",
    },

    // 7. Pan-D
    "8901234003311": {
      "name": "Pan-D",
      "dosage": "One capsule in the morning before eating anything",
      "uses": "Acidity, Nausea, Vomiting",
      "sideEffects": "Dry Mouth, Headache, Stomach Pain",
      "warning": "Do not crush or chew the capsule; swallow it whole.",
    },

    // 8. Gelusil MPS
    "8901234003344": {
      "name": "Gelusil MPS",
      "dosage": "One small spoon whenever you feel stomach burning",
      "uses": "Stomach Irritation, Burning Sensation",
      "sideEffects": "Metallic Taste In Mouth, Chalky Taste",
      "warning": "Avoid taking other medicines within 2 hours of this.",
    },

    // 9. Pudina Hara
    "8901234004455": {
      "name": "Pudina Hara",
      "dosage": "One green pearl with a glass of water after meals",
      "uses": "Stomach Ache, Gas",
      "sideEffects": "Minty Burps, Mild Burning In The Throat",
      "warning": "Swallow with water; do not bite the pearl.",
    },

    // 10. Omez 20
    "8901234004466": {
      "name": "Omez 20",
      "dosage": "One capsule daily before breakfast",
      "uses": "Excessive Stomach Acid",
      "sideEffects": "Nausea, Skin Rash, Joint Pain",
      "warning": "Long-term use may weaken bones; consult a doctor.",
    },

    // 11. Alerid
    "8901234005566": {
      "name": "Alerid",
      "dosage": "One tablet at night before sleeping",
      "uses": "Runny Nose, Sneezing, Skin Allergies",
      "sideEffects": "Sleepiness, Dry Mouth, Tiredness",
      "warning": "May cause drowsiness. Do not drive or drink alcohol.",
    },

    // 12. Vicks Action 500
    "8901234006677": {
      "name": "Vicks Action 500",
      "dosage": "One tablet with warm water for cold relief",
      "uses": "Common Cold, Sore Throat, Nasal Congestion",
      "sideEffects": "Dizziness, Blurred Vision, Restlessness",
      "warning": "Not recommended for children under 12 years.",
    },

    // 13. Allegra 120
    "8901234007788": {
      "name": "Allegra 120",
      "dosage": "One tablet daily with a glass of water",
      "uses": "Hay Fever, Skin Hives",
      "sideEffects": "Back Pain, Headache, Nausea",
      "warning": "Take only once in 24 hours with water.",
    },

    // 14. Otrivin Adult
    "8901234008899": {
      "name": "Otrivin Adult",
      "dosage": "One spray in each nostril, twice a day",
      "uses": "Blocked Nose, Sinus Pressure",
      "sideEffects": "Nasal Stinging, Sneezing, Dry Nose",
      "warning": "Do not use for more than 3 consecutive days.",
    },

    // 15. Ascoril LS
    "8901234009900": {
      "name": "Ascoril LS",
      "dosage": "One small spoon three times a day for chest congestion",
      "uses": "Wet Cough, Asthma, Chest Congestion",
      "sideEffects": "Tremors, Increased Heart Rate, Palpitations",
      "warning": "Consult a doctor if you have heart problems.",
    },

    // 16. Benadryl
    "8901234001112": {
      "name": "Benadryl",
      "dosage": "Two small spoons at night to stop dry cough",
      "uses": "Dry Cough, Throat Irritation, Runny Nose",
      "sideEffects": "Severe Drowsiness, Blurred Vision",
      "warning": "Known to cause deep sleep. Avoid nighttime overdose.",
    },

    // 17. Augmentin 625
    "8901234001111": {
      "name": "Augmentin 625",
      "dosage": "One tablet twice a day after meals",
      "uses": "Bacterial Infections, Throat, Lung, UTI, Dental",
      "sideEffects": "Vomiting, Loose Stools, Yeast Infection",
      "warning": "Complete the full course even if you feel better.",
    },

    // 18. Azithral 500
    "8901234002222": {
      "name": "Azithral 500",
      "dosage": "One tablet daily for 3 days at the same time",
      "uses": "Typhoid, Respiratory Infection, Skin Infection",
      "sideEffects": "Abdominal Pain, Nausea, Headache",
      "warning": "Usually taken once daily for 3 days only.",
    },

    // 19. Taxim-O 200
    "8901234003333": {
      "name": "Taxim-O 200",
      "dosage": "One tablet in the morning and one at night",
      "uses": "Urinary Tract, Ear Infection, Throat Infection",
      "sideEffects": "Diarrhea, Indigestion, Gas",
      "warning": "Avoid if you are allergic to Penicillin.",
    },

    // 20. Zenflox 200
    "8901234004445": {
      "name": "Zenflox 200",
      "dosage": "One tablet twice daily for infection",
      "uses": "Lung Infection, Urinary Tract Infection",
      "sideEffects": "Insomnia, Headache, Stomach Upset",
      "warning": "Avoid exposure to direct sunlight while on this med.",
    },

    // 21. Glycomet 500
    "8901234004444": {
      "name": "Glycomet 500",
      "dosage": "One tablet with your morning or night meal",
      "uses": "Type 2 Diabetes, Blood Sugar Control",
      "sideEffects": "Metallic Taste, Stomach Ache, Nausea",
      "warning": "Always take with a meal to reduce stomach upset.",
    },

    // 22. Telma 40
    "8901234005555": {
      "name": "Telma 40",
      "dosage": "One tablet daily, preferably at the same time",
      "uses": "High Blood Pressure, Hypertension",
      "sideEffects": "Dizziness, Back Pain, Sinus Inflammation",
      "warning": "Do not stop taking without consulting your doctor.",
    },

    // 23. Amlokind 5
    "8901234006666": {
      "name": "Amlokind 5",
      "dosage": "One tablet daily to keep blood pressure normal",
      "uses": "Hypertension, Chest Pain, Angina",
      "sideEffects": "Swelling Of Ankles, Feet, Fatigue, Flushing",
      "warning": "Avoid grapefruit juice while on this medication.",
    },

    // 24. Shelcal 500
    "8901234007777": {
      "name": "Shelcal 500",
      "dosage": "One tablet after a main meal for better absorption",
      "uses": "Bone Health, Calcium Deficiency",
      "sideEffects": "Thirst, Constipation, Stomach Upset",
      "warning": "Best taken after a main meal for better absorption.",
    },

    // 25. Becosules
    "8901234008888": {
      "name": "Becosules",
      "dosage": "One capsule daily, preferably in the morning",
      "uses": "Mouth Ulcers, Vitamin Deficiency",
      "sideEffects": "Yellow-Colored Urine (this is harmless)",
      "warning": "Take once daily, preferably in the morning.",
    },

    // 26. Liv.52
    "8901234009999": {
      "name": "Liv.52",
      "dosage": "One tablet twice daily before meals",
      "uses": "Liver Protection, Appetite Improvement",
      "sideEffects": "No Major Side Effects Reported",
      "warning": "Safe, but consult if you have jaundice symptoms.",
    },

    // 27. Atorva 10
    "8901234011223": {
      "name": "Atorva 10",
      "dosage": "One tablet at night before sleeping",
      "uses": "High Cholesterol, Heart Attack Prevention",
      "sideEffects": "Muscle Pain, Weakness, Digestive Upset",
      "warning": "Avoid excessive alcohol while taking statins.",
    },

    // 28. Thyronorm
    "8901234011334": {
      "name": "Thyronorm",
      "dosage": "One tablet on an empty stomach, 45 mins before breakfast",
      "uses": "Hypothyroidism, Thyroid Control",
      "sideEffects": "Weight Loss, Anxiety, Palpitations",
      "warning": "Must be taken on an empty stomach, 30-45 mins before breakfast.",
    },

    // 29. Orofer XT
    "8901234011445": {
      "name": "Orofer XT",
      "dosage": "One tablet after lunch",
      "uses": "Anemia, Iron Deficiency, Pregnancy Support",
      "sideEffects": "Dark-Colored Stools, Constipation",
      "warning": "Avoid taking with milk or tea as it blocks absorption.",
    },

    // 30. Septilin
    "8901234011556": {
      "name": "Septilin",
      "dosage": "One tablet or two spoons of syrup daily",
      "uses": "Immunity Booster, Chronic Infections",
      "sideEffects": "Very Rare Allergic Reactions",
      "warning": "Can be taken as a syrup or tablet as per dosage.",
    },
  };

  static Map<String, dynamic>? lookup(String code) {
    return database[code];
  }
}