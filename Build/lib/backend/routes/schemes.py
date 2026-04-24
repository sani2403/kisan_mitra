# ─────────────────────────────────────────────────────────────────────────────
# routes/schemes.py
#
# Government agricultural scheme data endpoint.
#
# ENDPOINTS:
#   GET /api/schemes                → all schemes
#   GET /api/schemes?category=Credit → filter by category
#   GET /api/schemes/<name>         → single scheme details
# ─────────────────────────────────────────────────────────────────────────────

from flask import Blueprint, jsonify, request

schemes_bp = Blueprint('schemes', __name__)

SCHEMES = [
    {
        "id": "pm_kisan",
        "name": "PM-KISAN",
        "full_name": "Pradhan Mantri Kisan Samman Nidhi",
        "category": "Income Support",
        "emoji": "💰",
        "color": "#1565C0",
        "benefit": "₹6,000/year",
        "description": "Direct income support of ₹6,000 per year to all farmer families in three equal installments.",
        "eligibility": ["Must be a cultivator/farmer", "Family must own agricultural land", "Valid Aadhaar card required", "Bank account linked to Aadhaar"],
        "apply_url": "https://pmkisan.gov.in",
        "documents": ["Aadhaar Card", "Land ownership documents", "Bank passbook"],
        "active": True,
    },
    {
        "id": "pmfby",
        "name": "PMFBY",
        "full_name": "Pradhan Mantri Fasal Bima Yojana",
        "category": "Crop Insurance",
        "emoji": "🛡️",
        "color": "#2E7D32",
        "benefit": "Full Coverage",
        "description": "Comprehensive crop insurance against natural calamities, pests and diseases with minimal premium.",
        "eligibility": ["All farmers growing notified crops", "Compulsory for loanee farmers", "Voluntary for non-loanee farmers"],
        "apply_url": "https://pmfby.gov.in",
        "documents": ["Aadhaar Card", "Bank Account", "Land records", "Sowing certificate"],
        "active": True,
    },
    {
        "id": "kcc",
        "name": "KCC",
        "full_name": "Kisan Credit Card Scheme",
        "category": "Credit",
        "emoji": "💳",
        "color": "#6A1B9A",
        "benefit": "Up to ₹3L",
        "description": "Short-term credit for crop cultivation, post-harvest expenses and allied activities at 4% interest rate.",
        "eligibility": ["All farmers — individual/joint borrowers", "Tenant farmers, oral lessees, share croppers", "SHGs/JLGs of farmers"],
        "apply_url": "https://www.nabard.org",
        "documents": ["Aadhaar Card", "Land records/Proof of cultivation", "Passport photo"],
        "active": True,
    },
    {
        "id": "pmksy",
        "name": "PMKSY",
        "full_name": "Pradhan Mantri Krishi Sinchayee Yojana",
        "category": "Irrigation",
        "emoji": "💧",
        "color": "#00838F",
        "benefit": "90% Subsidy",
        "description": "Har Khet Ko Pani, More Crop Per Drop — expanding irrigation coverage with drip/sprinkler subsidies.",
        "eligibility": ["All categories of farmers", "Priority to SC/ST/small/marginal farmers"],
        "apply_url": "https://pmksy.gov.in",
        "documents": ["Aadhaar Card", "Land records", "Bank account"],
        "active": True,
    },
    {
        "id": "pkvy",
        "name": "PKVY",
        "full_name": "Paramparagat Krishi Vikas Yojana",
        "category": "Income Support",
        "emoji": "🌿",
        "color": "#558B2F",
        "benefit": "₹50,000/ha",
        "description": "Support for organic farming clusters and certification of organic produce for premium prices.",
        "eligibility": ["Farmers willing to adopt organic farming", "Must form cluster of 50 farmers/50 ha"],
        "apply_url": "https://pgsindia-ncof.gov.in",
        "documents": ["Aadhaar Card", "Land records", "Group formation documents"],
        "active": True,
    },
    {
        "id": "rkvy",
        "name": "RKVY",
        "full_name": "Rashtriya Krishi Vikas Yojana",
        "category": "Income Support",
        "emoji": "🏗️",
        "color": "#E65100",
        "benefit": "Flexible Grants",
        "description": "Holistic development of agriculture and allied sectors through need-based and result-oriented planning.",
        "eligibility": ["State government–driven scheme", "Farmers benefit through state-implemented projects"],
        "apply_url": "https://rkvy.nic.in",
        "documents": ["Apply through state agriculture department"],
        "active": True,
    },
    {
        "id": "nhm",
        "name": "NHM",
        "full_name": "National Horticulture Mission",
        "category": "Income Support",
        "emoji": "🌸",
        "color": "#00695C",
        "benefit": "50% Subsidy",
        "description": "Holistic development of horticulture sector to enhance farmer income and exports.",
        "eligibility": ["Farmers cultivating horticulture crops", "Prioritizes fruits, vegetables, spices, flowers"],
        "apply_url": "https://nhm.nic.in",
        "documents": ["Aadhaar Card", "Land records", "Horticulture dept. registration"],
        "active": True,
    },
]


@schemes_bp.route('/schemes', methods=['GET'])
def get_schemes():
    category = request.args.get('category', None)
    if category:
        filtered = [s for s in SCHEMES if s['category'].lower() == category.lower()]
        return jsonify({'total': len(filtered), 'schemes': filtered}), 200
    return jsonify({'total': len(SCHEMES), 'schemes': SCHEMES}), 200


@schemes_bp.route('/schemes/<scheme_id>', methods=['GET'])
def get_scheme(scheme_id):
    scheme = next((s for s in SCHEMES if s['id'] == scheme_id), None)
    if not scheme:
        return jsonify({'error': f'Scheme "{scheme_id}" not found'}), 404
    return jsonify(scheme), 200
